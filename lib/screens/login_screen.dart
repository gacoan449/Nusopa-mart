import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}

  Future<void> _login() async {
    if(email.text.trim().isEmpty || password.text.isEmpty){_msg('Email dan password wajib diisi');return;}
    setState(()=>loading=true);
    try {
      final result=await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      final uid=result.user!.uid;
      final doc=await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if(!doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': result.user!.email,
          'role':'BUYER',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge:true));
      }
      if(mounted) Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AuthGate()),(_)=>false);
    } on FirebaseAuthException catch(e) {_msg(e.message??'Login gagal');}
    finally {if(mounted)setState(()=>loading=false);}
  }
  void _msg(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:420),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Icon(Icons.storefront,size:72,color:Color(0xFFFF5722)),
        const SizedBox(height:12),const Text('Nusopa.Mart',textAlign:TextAlign.center,style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),
        const SizedBox(height:32),
        TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())),
        const SizedBox(height:16),
        TextField(controller:password,obscureText:true,onSubmitted:(_)=>_login(),decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder())),
        const SizedBox(height:20),SizedBox(height:52,child:FilledButton(onPressed:loading?null:_login,child:loading?const CircularProgressIndicator():const Text('MASUK'))),
        const SizedBox(height:12),const Text('Akun ADMIN dan SELLER ditentukan oleh field role pada Firestore oleh pemilik sistem.',textAlign:TextAlign.center),
      ]))))));
}
