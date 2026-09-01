import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'webrtc_call_service.dart';

class CallNotificationService {
  CallNotificationService._();
  static final instance = CallNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<User?>? _authSub;
  bool _initialized = false;
  bool _overlayOpen = false;
  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initialize(GlobalKey<NavigatorState> key) async {
    if (_initialized) return;
    navigatorKey = key;
    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveToken(await _messaging.getToken());
    _messaging.onTokenRefresh.listen(_saveToken);
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    _authSub = _auth.authStateChanges().listen((_) async {
      await _saveToken(await _messaging.getToken());
      _listenForIncomingCalls();
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) await _handleOpenedMessage(initial);
    _listenForIncomingCalls();
  }

  Future<void> _saveToken(String? token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token == null || token.isEmpty) return;
    await _db.collection('fcm_tokens').doc(uid).set({'token': token, 'platform': 'android', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  void _listenForIncomingCalls() {
    final uid = _auth.currentUser?.uid;
    _callSub?.cancel();
    if (uid == null) return;
    _callSub = _db.collection('calls').where('calleeId', isEqualTo: uid).where('status', isEqualTo: 'ringing').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty || _overlayOpen) return;
      final doc = snapshot.docs.first;
      _showIncoming(doc.id, doc.data());
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['type'] != 'incoming_call') return;
    await _showCallFromId(message.data['callId']?.toString());
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    if (message.data['type'] != 'incoming_call') return;
    await _showCallFromId(message.data['callId']?.toString());
  }

  Future<void> _showCallFromId(String? id) async {
    if (id == null || id.isEmpty) return;
    final snapshot = await _db.collection('calls').doc(id).get();
    final data = snapshot.data();
    if (data != null && data['status'] == 'ringing' && data['calleeId'] == _auth.currentUser?.uid) _showIncoming(id, data);
  }

  void _showIncoming(String id, Map<String, dynamic> data) {
    final context = navigatorKey?.currentState?.overlay?.context;
    if (context == null || _overlayOpen) return;
    _overlayOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingCallOverlay(
        callId: id,
        callerName: (data['callerName'] ?? 'Pengguna').toString(),
        video: data['type'] == 'video',
        onClosed: () => _overlayOpen = false,
      ),
    );
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _callSub?.cancel();
    _authSub?.cancel();
  }
}

class IncomingCallOverlay extends StatelessWidget {
  final String callId;
  final String callerName;
  final bool video;
  final VoidCallback onClosed;
  const IncomingCallOverlay({super.key, required this.callId, required this.callerName, required this.video, required this.onClosed});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Panggilan Masuk'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
      const SizedBox(height: 14),
      Text(callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(video ? 'Panggilan video' : 'Panggilan suara'),
    ]),
    actionsAlignment: MainAxisAlignment.spaceEvenly,
    actions: [
      IconButton.filled(style: IconButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await WebRtcCallService.instance.decline(); onClosed(); if (context.mounted) Navigator.of(context).pop(); }, icon: const Icon(Icons.call_end)),
      IconButton.filled(style: IconButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () async {
        try {
          await WebRtcCallService.instance.acceptCall(callId);
          onClosed();
          if (context.mounted) { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallScreen(video: video, incoming: true))); }
        } catch (e) {
          onClosed();
          if (context.mounted) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Panggilan sudah berakhir: $e'))); }
        }
      }, icon: const Icon(Icons.call)),
    ],
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payload is rendered by Android in background/terminated states.
}

class CallScreen extends StatefulWidget {
  final bool video;
  final bool incoming;
  const CallScreen({super.key, required this.video, this.incoming = false});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  final service = WebRtcCallService.instance;
  bool muted = false;
  bool cameraEnabled = true;
  Timer? clock;
  DateTime startedAt = DateTime.now();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); clock = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && mounted) setState(() {}); }
  Future<void> endCall() async { await service.end(); if (mounted) Navigator.of(context).pop(); }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: RTCVideoView(service.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
        if (widget.video) Positioned(top: 48, right: 16, width: 120, height: 170, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: RTCVideoView(service.localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))),
        Positioned(top: 48, left: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(_duration(), style: const TextStyle(color: Colors.white)))),
        Positioned(left: 0, right: 0, bottom: 30, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _control(muted ? Icons.mic_off : Icons.mic, () { service.toggleMute(); setState(() => muted = !muted); }),
          if (widget.video) _control(cameraEnabled ? Icons.videocam : Icons.videocam_off, () { service.toggleCamera(); setState(() => cameraEnabled = !cameraEnabled); }),
          if (widget.video) _control(Icons.cameraswitch, service.switchCamera),
          _control(Icons.call_end, endCall, danger: true),
        ])),
      ]),
    ),
  );

  Widget _control(IconData icon, VoidCallback action, {bool danger = false}) => IconButton.filled(onPressed: action, style: IconButton.styleFrom(backgroundColor: danger ? Colors.red : Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)), icon: Icon(icon));
  String _duration() { final d = DateTime.now().difference(startedAt); return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}'; }

  @override
  void dispose() { clock?.cancel(); WidgetsBinding.instance.removeObserver(this); unawaited(service.stop(deleteCallDocument: false)); super.dispose(); }
}
