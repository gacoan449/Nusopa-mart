import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Pure P2P WebRTC engine. Firestore carries signaling metadata/ICE only.
class WebRtcCallService {
  WebRtcCallService._();
  static final instance = WebRtcCallService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? peer;
  MediaStream? localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteCandidateSub;
  Timer? timeoutTimer;

  String? callId;
  String? otherUid;
  bool isCaller = false;
  bool isVideo = false;
  bool _cleaned = true;
  bool _renderersInitialized = false;
  final Set<String> _addedCandidateIds = <String>{};

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302']},
      {'urls': ['stun:stun1.l.google.com:19302']},
    ],
    'sdpSemantics': 'unified-plan',
  };

  String get uid => _auth.currentUser?.uid ?? (throw StateError('Sesi berakhir.'));
  bool get hasActiveCall => callId != null && peer != null;

  DocumentReference<Map<String, dynamic>> get _call {
    final id = callId;
    if (id == null) throw StateError('Tidak ada panggilan aktif.');
    return _db.collection('calls').doc(id);
  }

  Future<void> _initRenderers() async {
    if (_renderersInitialized) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersInitialized = true;
  }

  Future<void> _prepareMediaAndPeer() async {
    await _initRenderers();
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });
    localRenderer.srcObject = localStream;

    peer = await createPeerConnection(_config);
    _cleaned = false;
    for (final track in localStream!.getTracks()) {
      await peer!.addTrack(track, localStream!);
    }

    peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) remoteRenderer.srcObject = event.streams.first;
    };

    peer!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null || callId == null) return;
      final collection = isCaller ? 'callerCandidates' : 'calleeCandidates';
      try {
        await _call.collection(collection).add(candidate.toMap());
      } catch (e) {
        debugPrint('WebRTC ICE write error: $e');
      }
    };

    peer!.onConnectionState = (state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        try {
          await _call.update({'status': 'connected', 'connectedAt': FieldValue.serverTimestamp()});
        } catch (_) {}
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        try {
          await _call.update({'status': 'disconnected', 'endedAt': FieldValue.serverTimestamp()});
        } catch (_) {}
      }
    };
  }

  Future<String> createCall({required String targetUid, required bool video, String? callerName}) async {
    if (targetUid.isEmpty || targetUid == uid) throw ArgumentError('Penerima tidak valid.');
    await stop(deleteCallDocument: false);

    isCaller = true;
    otherUid = targetUid;
    isVideo = video;
    callId = _db.collection('calls').doc().id;
    _addedCandidateIds.clear();

    // Create the signaling document before gathering ICE so candidate callbacks
    // can safely write immediately after setLocalDescription().
    await _call.set({
      'callerId': uid,
      'calleeId': targetUid,
      'participants': [uid, targetUid],
      'callerName': callerName ?? _auth.currentUser?.displayName ?? 'Pengguna',
      'type': video ? 'video' : 'voice',
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _prepareMediaAndPeer();
    final offer = await peer!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': video});
    await peer!.setLocalDescription(offer);
    await _call.update({'offer': offer.toMap()});

    _listenToCallDocument();
    _listenForRemoteCandidates('calleeCandidates');
    _startRingTimeout();
    return callId!;
  }

  Future<void> acceptCall(String id) async {
    await stop(deleteCallDocument: false);
    isCaller = false;
    callId = id;
    _addedCandidateIds.clear();

    final snapshot = await _call.get();
    final data = snapshot.data();
    if (data == null || data['calleeId'] != uid || data['status'] != 'ringing' || data['offer'] == null) {
      callId = null;
      throw StateError('Panggilan sudah tidak tersedia.');
    }

    otherUid = data['callerId'] as String?;
    isVideo = data['type'] == 'video';
    await _prepareMediaAndPeer();

    final offer = Map<String, dynamic>.from(data['offer'] as Map);
    await peer!.setRemoteDescription(RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));
    final answer = await peer!.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': isVideo});
    await peer!.setLocalDescription(answer);
    await _call.update({'answer': answer.toMap(), 'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp()});

    _listenForRemoteCandidates('callerCandidates');
    _listenToCallDocument();
    // The 45-second timer applies only while ringing, not after acceptance.
  }

  void _listenToCallDocument() {
    callSub?.cancel();
    callSub = _call.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;
      final status = data['status']?.toString();

      if (isCaller && data['answer'] != null && peer != null) {
        final current = await peer!.getRemoteDescription();
        if (current == null) {
          final answer = Map<String, dynamic>.from(data['answer'] as Map);
          await peer!.setRemoteDescription(RTCSessionDescription(answer['sdp'] as String, answer['type'] as String));
        }
      }

      if (status == 'declined' || status == 'disconnected' || status == 'ended' || status == 'timeout' || status == 'no_answer') {
        await stop(deleteCallDocument: false);
      }
    });
  }

  void _listenForRemoteCandidates(String collection) {
    remoteCandidateSub?.cancel();
    remoteCandidateSub = _call.collection(collection).snapshots().listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added || peer == null) continue;
        if (!_addedCandidateIds.add(change.doc.id)) continue;
        final data = change.doc.data();
        if (data == null) continue;
        try {
          await peer!.addCandidate(RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            (data['sdpMLineIndex'] as num?)?.toInt(),
          ));
        } catch (e) {
          debugPrint('WebRTC ICE read error: $e');
        }
      }
    });
  }

  void _startRingTimeout() {
    timeoutTimer?.cancel();
    timeoutTimer = Timer(const Duration(seconds: 45), () async {
      if (callId == null) return;
      try {
        final snapshot = await _call.get();
        final status = snapshot.data()?['status']?.toString();
        if (status == 'ringing') {
          await _call.update({'status': 'no_answer', 'endedAt': FieldValue.serverTimestamp()});
        }
      } catch (_) {}
    });
  }

  Future<void> decline() async {
    if (callId == null) return;
    try {
      await _call.update({'status': 'declined', 'endedAt': FieldValue.serverTimestamp()});
    } finally {
      await stop(deleteCallDocument: false);
    }
  }

  Future<void> end() async {
    if (callId == null) {
      await stop(deleteCallDocument: false);
      return;
    }
    try {
      await _call.update({'status': 'disconnected', 'endedAt': FieldValue.serverTimestamp()});
    } finally {
      await stop(deleteCallDocument: false);
    }
  }

  void toggleMute() {
    for (final track in localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) track.enabled = !track.enabled;
  }

  bool get isMuted => !(localStream?.getAudioTracks().firstOrNull?.enabled ?? true);

  void toggleCamera() {
    for (final track in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) track.enabled = !track.enabled;
  }

  bool get isCameraEnabled => localStream?.getVideoTracks().firstOrNull?.enabled ?? false;

  Future<void> switchCamera() async {
    for (final track in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) await Helper.switchCamera(track);
  }

  /// Full resource teardown. Safe to call more than once.
  Future<void> stop({bool deleteCallDocument = false}) async {
    if (_cleaned && peer == null && localStream == null && !_renderersInitialized) return;
    _cleaned = true;
    timeoutTimer?.cancel();
    timeoutTimer = null;

    await callSub?.cancel();
    await remoteCandidateSub?.cancel();
    callSub = null;
    remoteCandidateSub = null;

    final stream = localStream;
    localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        try { track.stop(); } catch (_) {}
      }
      try { await stream.dispose(); } catch (_) {}
    }

    final connection = peer;
    peer = null;
    if (connection != null) {
      try { await connection.close(); } catch (_) {}
    }

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    if (_renderersInitialized) {
      try { await localRenderer.dispose(); } catch (_) {}
      try { await remoteRenderer.dispose(); } catch (_) {}
      _renderersInitialized = false;
    }

    if (deleteCallDocument && callId != null) {
      try { await _call.delete(); } catch (_) {}
    }

    callId = null;
    otherUid = null;
    isCaller = false;
    isVideo = false;
    _addedCandidateIds.clear();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
