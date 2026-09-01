import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return const Scaffold(body:Center(child:Text('Silakan masuk kembali.')));
    return Scaffold(appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:Text('Pesanan Saya',style:GoogleFonts.inter(fontWeight:FontWeight.w800))),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').where('buyerId',isEqualTo:user.uid).snapshots(),builder:(context,s){
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Pesanan tidak dapat dimuat: '+s.error.toString()));
      final docs=s.data?.docs??[];if(docs.isEmpty)return const Center(child:Text('Belum ada pesanan.'));
      return ListView.separated(padding:const EdgeInsets.all(16),itemCount:docs.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i){final d=docs[i],x=d.data();return Card(child:ListTile(title:Text((x['productName']??'Produk').toString(),style:GoogleFonts.inter(fontWeight:FontWeight.w700)),subtitle:Text('Status: '+(x['status']??'-').toString()+'\nTotal: Rp'+(x['total']??0).toString()),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TrackingScreen(order:OrderModel.fromMap(x,d.id)))));});}));}
}