import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../services/rekber_service.dart';

class TrackingScreen extends StatelessWidget{
 final OrderModel order;const TrackingScreen({super.key,required this.order});static const blue=Color(0xFF126BFF);
 Future<void> _open(BuildContext c)async{final link=order.linkCekLogistik;if(link==null||link.isEmpty)return;await launchUrl(Uri.parse(link),mode:LaunchMode.externalApplication);}
 @override Widget build(BuildContext c){final buyer=FirebaseAuth.instance.currentUser?.uid==order.buyerId;return Scaffold(backgroundColor:const Color(0xFFF5F8FF),appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:const Text('Status Pesanan')),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[blue,Color(0xFF62B6FF)]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(order.status.replaceAll('_',' '),style:GoogleFonts.inter(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(order.productName,style:const TextStyle(color:Colors.white70))])),
 const SizedBox(height:18),_card('Ekspedisi',order.namaEkspedisi??'Belum diinput penjual',Icons.local_shipping_outlined),_card('Nomor resi',order.nomorResi??'Belum diterbitkan',Icons.confirmation_number_outlined,onTap:order.nomorResi==null?null:()=>Clipboard.setData(ClipboardData(text:order.nomorResi!))),
 const SizedBox(height:12),if(order.fotoResiUrl!=null&&order.fotoResiUrl!.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.network(order.fotoResiUrl!,height:220,width:double.infinity,fit:BoxFit.cover)),
 if(order.linkCekLogistik!=null&&order.linkCekLogistik!.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(onPressed:()=>_open(c),icon:const Icon(Icons.travel_explore),label:const Text('CEK DI WEB EKSPEDISI'))),
 if(buyer&&order.status=='DIKIRIM')Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.green),onPressed:()=>RekberService.instance.confirmReceived(order.orderId),icon:const Icon(Icons.check_circle),label:const Text('KONFIRMASI BARANG DITERIMA'))),
 const SizedBox(height:18),Text('Alur transaksi',style:GoogleFonts.inter(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:10),...['MENUNGGU_PEMBAYARAN','MENUNGGU_VERIFIKASI','DIBAYAR','DIPROSES','SIAP_DIKIRIM','DIKIRIM','DITERIMA','SELESAI'].map((s)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Icon(order.status==s?Icons.check_circle:Icons.radio_button_unchecked,color:order.status==s?Colors.green:Colors.grey,size:19),const SizedBox(width:9),Text(s.replaceAll('_',' '))])))
]));}
 Widget _card(String t,String v,IconData i,{VoidCallback? onTap})=>Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),child:ListTile(onTap:onTap,leading:Icon(i,color:blue),title:Text(t),subtitle:Text(v),trailing:onTap==null?null:const Icon(Icons.copy)));
}