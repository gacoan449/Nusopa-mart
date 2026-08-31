import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NusopaMartApp());
}
class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Nusopa.Mart',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFFF5722)),
    home: const AuthGate(),
  );
}
