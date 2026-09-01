import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_screen.dart';
import 'seller_dashboard.dart';
import 'rekber_info_screen.dart';
import 'rekber_home_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  static const blue=Color(0xFF126BFF);
  @override Widget build(BuildContext context){final user=FirebaseAuth.instance.currentUser;return Scaffold(backgroundColor:const Color(0xFFF5F8FF),appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:const Text('Saya')),body:ListView(padding:const EdgeInsets.all(16),children:[Card(elevation:0,child:ListTile(contentPadding:const EdgeInsets.all(16),leading:const CircleAvatar(radius:30,backgroundColor:Color(0xFFEAF3FF),child:Icon(Icons.person,color:blue,size:34)),title:Text('Akun Nusopa.Mart',style:GoogleFonts.inter(fontWeight:FontWeight.w800,fontSize:17)),subtitle:Text(user?.email??'Pengguna'))),const SizedBox(height:10),_tile(context,Icons.shield_outlined,'Rekber','Transaksi aktif, riwayat dan invoice',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RekberHomeScreen()))),_tile(context,Icons.receipt_long_outlined,'Pesanan Saya','Status dan detail transaksi',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OrdersScreen()))),_tile(context,Icons.storefront_outlined,'Jual Barang','Kelola toko, produk, stok dan pesanan',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SellerDashboard()))),_tile(context,Icons.info_outline,'Aturan & Rekber','Biaya, alur, keamanan dan sengketa',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RekberInfoScreen()))),Card(elevation:0,child:ListTile(leading:const Icon(Icons.logout,color:Colors.redAccent),title:const Text('Keluar'),onTap:()=>FirebaseAuth.instance.signOut()))]) );}
  Widget _tile(BuildContext context,IconData icon,String title,String subtitle,VoidCallback onTap)=>Card(elevation:0,child:ListTile(onTap:onTap,leading:CircleAvatar(backgroundColor:blue.withValues(alpha:.1),child:Icon(icon,color:blue)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right)));
}
