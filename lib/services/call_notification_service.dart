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
  bool _initialized = false;
  bool _overlayOpen = false;
  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initialize(GlobalKey<NavigatorState> key) async {
    if (_initialized) return;
    navigatorKey = key;
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true, criticalAlert: true);
    final token = await _messaging.getToken();
    await _saveToken(token);
    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handleOpenedMessage(initial);
    }

    _listenForIncomingCalls();
  }

  Future<void> _saveToken(String? token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token == null || token.isEmpty) return;
    await _db.collection('fcm_tokens').doc(uid).set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenForIncomingCalls() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _callSub?.cancel();
    _callSub = _db.collection('calls').where('calleeId', isEqualTo: uid).where('status', isEqualTo: 'ringing').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty || _overlayOpen) return;
      final data = snapshot.docs.first.data();
      _showIncoming(snapshot.docs.first.id, data);
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['type'] != 'incoming_call') return;
    final callId = message.data['callId']?.toString();
    if (callId == null || callId.isEmpty) return;
    final snapshot = await _db.collection('calls').doc(callId).get();
    final data = snapshot.data();
    if (data != null && data['status'] == 'ringing') {
      _showIncoming(callId, data);
    }
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    if (message.data['type'] != 'incoming_call') return;
    final callId = message.data['callId']?.toString();
    if (callId == null || callId.isEmpty) return;
    final snapshot = await _db.collection('calls').doc(callId).get();
    final data = snapshot.data();
    if (data != null && data['status'] == 'ringing') {
      _showIncoming(callId, data);
    }
  }

  void _showIncoming(String callId, Map<String, dynamic> data) {
    final context = navigatorKey?.currentState?.overlay?.context;
    if (context == null || _overlayOpen) return;
    _overlayOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingCallOverlay(
        callId: callId,
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
    _foregroundSub = null;
    _openedSub = null;
    _callSub = null;
  }
}

class IncomingCallOverlay extends StatelessWidget {
  final String callId;
  final String callerName;
  final bool video;
  final VoidCallback onClosed;
  const IncomingCallOverlay({super.key, required this.callId, required this.callerName, required this.video, required this.onClosed});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
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
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await WebRtcCallService.instance.decline();
              onClosed();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.call_end),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await WebRtcCallService.instance.acceptCall(callId);
                onClosed();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallScreen(video: video, incoming: true)));
                }
              } catch (e) {
                onClosed();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Panggilan sudah berakhir: $e')));
                }
              }
            },
            icon: const Icon(Icons.call),
          ),
        ],
      ),
    );
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM notification payload is displayed by Android while the process is backgrounded/terminated.
  // Data-only messages are intentionally not used for ringing because Android may not start a terminated Dart isolate.
}

// Imported lazily to keep this service usable by the notification layer.
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
  DateTime? startedAt;
  Timer? clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startedAt = DateTime.now();
    clock = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not stop the peer on lifecycle transitions. Android may temporarily pause Flutter.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Future<void> endCall() async {
    await service.end();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: RTCVideoView(service.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
          if (widget.video)
            Positioned(top: 48, right: 16, width: 120, height: 170, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: RTCVideoView(service.localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))),
          Positioned(top: 48, left: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(_duration(), style: const TextStyle(color: Colors.white)))),
          Positioned(left: 0, right: 0, bottom: 30, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _control(muted ? Icons.mic_off : Icons.mic, muted ? 'Unmute' : 'Mute', () { service.toggleMute(); setState(() => muted = !muted); }),
            if (widget.video) _control(cameraEnabled ? Icons.videocam : Icons.videocam_off, cameraEnabled ? 'Camera' : 'Camera off', () { service.toggleCamera(); setState(() => cameraEnabled = !cameraEnabled); }),
            if (widget.video) _control(Icons.cameraswitch, 'Switch', service.switchCamera),
            _control(Icons.call_end, 'End', endCall, danger: true),
          ])),
        ]),
      ),
    );
  }

  Widget _control(IconData icon, String label, VoidCallback action, {bool danger = false}) => Column(children: [IconButton.filled(onPressed: action, style: IconButton.styleFrom(backgroundColor: danger ? Colors.red : Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)), icon: Icon(icon)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))]);
  String _duration() { final d = DateTime.now().difference(startedAt ?? DateTime.now()); return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}'; }

  @override
  void dispose() {
    clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    service.stop(deleteCallDocument: false);
    super.dispose();
  }
}
