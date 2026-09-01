import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Pure peer-to-peer WebRTC call engine.
/// Firebase is signaling only; media is never stored in Firebase.
class WebRtcCallService {
  WebRtcCallService._();
  static final instance = WebRtcCallService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  RTCPeerConnection? peer;
  MediaStream? localStream;
  StreamSubscription? callSub;
  StreamSubscription? offerSub;
  StreamSubscription? answerSub;
  StreamSubscription? callerCandidatesSub;
  StreamSubscription? calleeCandidatesSub;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  String? callId;
  String? otherUid;
  bool isCaller = false;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('Sesi berakhir.'));
  DocumentReference<Map<String,dynamic>> get _call => _db.collection('calls').doc(callId);

  static const _config = {
    'iceServers': [
      {'urls': ['stun:stun.l.google.com:19302']},
      {'urls': ['stun:stun1.l.google.com:19302']},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> _prepare({required bool video}) async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    localRenderer.srcObject = localStream;
    peer = await createPeerConnection(_config);
    for (final track in localStream!.getTracks()) {
      await peer!.addTrack(track, localStream!);
    }
    peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) remoteRenderer.srcObject = event.streams.first;
    };
    peer!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null || callId == null) return;
      final side = isCaller ? 'callerCandidates' : 'calleeCandidates';
      await _call.collection(side).add(candidate.toMap());
    };
    peer!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _call.update({'status': 'connected', 'connectedAt': FieldValue.serverTimestamp()});
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _call.update({'status': 'disconnected', 'endedAt': FieldValue.serverTimestamp()});
      }
    };
  }

  Future<String> createCall({required String targetUid, required bool video}) async {
    if (targetUid.isEmpty || targetUid == uid) throw ArgumentError('Penerima tidak valid.');
    await stop();
    isCaller = true;
    otherUid = targetUid;
    callId = _db.collection('calls').doc().id;
    await _prepare(video: video);
    final offer = await peer!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': video});
    await peer!.setLocalDescription(offer);
    await _call.set({
      'callerId': uid, 'calleeId': targetUid, 'type': video ? 'video' : 'voice',
      'status': 'ringing', 'offer': offer.toMap(), 'createdAt': FieldValue.serverTimestamp(),
    });
    _listenForAnswer();
    _listenForRemoteCandidates('calleeCandidates');
    return callId!;
  }

  Future<void> acceptCall(String id) async {
    await stop();
    isCaller = false;
    callId = id;
    final data = (await _call.get()).data();
    if (data == null || data['calleeId'] != uid || data['status'] != 'ringing') throw StateError('Panggilan tidak tersedia.');
    otherUid = data['callerId'] as String?;
    await _prepare(video: data['type'] == 'video');
    final offer = data['offer'] as Map<String,dynamic>;
    await peer!.setRemoteDescription(RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));
    final answer = await peer!.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': data['type'] == 'video'});
    await peer!.setLocalDescription(answer);
    await _call.update({'answer': answer.toMap(), 'status': 'ringing'});
    _listenForRemoteCandidates('callerCandidates');
  }

  void _listenForAnswer() {
    answerSub?.cancel();
    answerSub = _call.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null || data['answer'] == null || peer == null) return;
      final current = await peer!.getRemoteDescription();
      if (current != null) return;
      final a = data['answer'] as Map<String,dynamic>;
      await peer!.setRemoteDescription(RTCSessionDescription(a['sdp'] as String, a['type'] as String));
    });
  }

  void _listenForRemoteCandidates(String collection) {
    final sub = _call.collection(collection).snapshots().listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added || peer == null) continue;
        final d = change.doc.data();
        if (d == null) continue;
        try {
          await peer!.addCandidate(RTCIceCandidate(d['candidate'] as String?, d['sdpMid'] as String?, (d['sdpMLineIndex'] as num?)?.toInt()));
        } catch (_) {}
      }
    });
    if (collection == 'callerCandidates') callerCandidatesSub = sub; else calleeCandidatesSub = sub;
  }

  Future<void> decline() => _call.update({'status': 'declined', 'endedAt': FieldValue.serverTimestamp()});
  Future<void> end() => _call.update({'status': 'disconnected', 'endedAt': FieldValue.serverTimestamp()});

  void toggleMute() { for (final t in localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) t.enabled = !t.enabled; }
  void toggleCamera() { for (final t in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) t.enabled = !t.enabled; }
  Future<void> switchCamera() async { for (final t in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) await Helper.switchCamera(t); }

  Future<void> stop() async {
    await callSub?.cancel(); await offerSub?.cancel(); await answerSub?.cancel(); await callerCandidatesSub?.cancel(); await calleeCandidatesSub?.cancel();
    callSub = offerSub = answerSub = callerCandidatesSub = calleeCandidatesSub = null;
    for (final t in localStream?.getTracks() ?? <MediaStreamTrack>[]) { try { t.stop(); } catch (_) {} }
    try { await localStream?.dispose(); } catch (_) {}
    localStream = null;
    try { await peer?.close(); } catch (_) {}
    peer = null;
    localRenderer.srcObject = null; remoteRenderer.srcObject = null;
    try { await localRenderer.dispose(); } catch (_) {}
    try { await remoteRenderer.dispose(); } catch (_) {}
    callId = null; otherUid = null; isCaller = false;
  }
}
