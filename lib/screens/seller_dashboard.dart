import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'seller_products_screen.dart';
import 'seller_orders_screen.dart';
import 'admin_core.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});
  static const blue=Color(0xFF126BFF);
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('Sesi berakhir.')));
    final db=FirebaseFirestore.instance;
    return Scaffold(backgroundColor:const Color(0xFFF5F8FF),
      appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:Text('Nusopa Seller',style:GoogleFonts.inter(fontWeight:FontWeight.w800,color:blue)),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChatAdminScreen())),icon:const Icon(Icons.headset_mic_rounded,color:blue))]),
      body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:db.collection('stores').doc(uid).snapshots(),builder:(context,storeSnap){
        final store=storeSnap.data?.data()??{};
        final storeName=(store['name']??'Toko Saya').toString();
        return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('orders').where('sellerId',isEqualTo:uid).snapshots(),builder:(context,orderSnap){
          final orders=orderSnap.data?.docs??[];
          final incoming=orders.where((d)=>['DIBAYAR','DIPROSES'].contains(d.data()['status'])).length;
          final ready=orders.where((d)=>d.data()['status']=='SIAP_DIKIRIM').length;
          final sent=orders.where((d)=>d.data()['status']=='DIKIRIM').length;
          return ListView(padding:const EdgeInsets.all(16),children:[
            Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF126BFF),Color(0xFF62B6FF)]),borderRadius:BorderRadius.circular(24),boxShadow:[BoxShadow(color:blue.withValues(alpha: .25),blurRadius:22,offset:const Offset(0,10))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(storeName,style:GoogleFonts.inter(color:Colors.white,fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text((store['phone']??FirebaseAuth.instance.currentUser?.email??'').toString(),style:GoogleFonts.inter(color:Colors.white70)),const SizedBox(height:14),const Text('Dashboard data langsung dari Firebase',style:TextStyle(color:Colors.white,fontSize:12))])),
            const SizedBox(height:16),
            Row(children:[Expanded(child:_stat('Pesanan baru',incoming,Icons.shopping_bag_outlined)),const SizedBox(width:10),Expanded(child:_stat('Siap kirim',ready,Icons.inventory_2_outlined)),const SizedBox(width:10),Expanded(child:_stat('Dikirim',sent,Icons.local_shipping_outlined))]),
            const SizedBox(height:20),Text('Kelola toko',style:GoogleFonts.inter(fontSize:17,fontWeight:FontWeight.w800)),
            const SizedBox(height:10),
            _tile(context,Icons.inventory_2_rounded,'Produk Saya','Tambah, edit, stok, harga dan foto',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SellerProductsScreen()))),
            _tile(context,Icons.local_shipping_rounded,'Pesanan Penjual','Proses order, ekspedisi, resi dan bukti foto',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SellerOrdersScreen()))),
            _tile(context,Icons.headset_mic_rounded,'Chat Admin','Chat online realtime dan bantuan',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChatAdminScreen()))),
          ]);
        });
      }),
    );
  }
  Widget _stat(String t,int v,IconData i)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Column(children:[Icon(i,color:blue),const SizedBox(height:6),Text(v.toString(),style:GoogleFonts.inter(fontWeight:FontWeight.w800,fontSize:18)),Text(t,textAlign:TextAlign.center,style:GoogleFonts.inter(fontSize:10,color:Colors.grey))]));
  Widget _tile(BuildContext c,IconData i,String t,String s,VoidCallback tap)=>Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:ListTile(onTap:tap,leading:CircleAvatar(backgroundColor:blue.withValues(alpha: .1),child:Icon(i,color:blue)),title:Text(t,style:GoogleFonts.inter(fontWeight:FontWeight.w700)),subtitle:Text(s,style:GoogleFonts.inter(fontSize:11)),trailing:const Icon(Icons.chevron_right)));
}