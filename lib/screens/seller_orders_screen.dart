import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(appBar:AppBar(title:const Text('Pesanan Penjual')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('orders').where('sellerId',isEqualTo:uid).snapshots(),builder:(c,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final docs=s.data?.docs??[];if(docs.isEmpty)return const Center(child:Text('Belum ada pesanan.'));return ListView.builder(itemCount:docs.length,itemBuilder:(_,i){final d=docs[i],x=d.data();return Card(child:ListTile(title:Text((x['productName']??'Produk').toString()),subtitle:Text('Status: '+(x['status']??'-').toString()+'\nTotal Rp'+(x['total']??0).toString()),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SellerOrderDetail(id:d.id,data:x))));});}));
  }
}
class SellerOrderDetail extends StatefulWidget {final String id;final Map<String,dynamic> data;const SellerOrderDetail({super.key,required this.id,required this.data});@override State<SellerOrderDetail> createState()=>_SellerOrderDetailState();}
class _SellerOrderDetailState extends State<SellerOrderDetail>{
 final courier=TextEditingController(),resi=TextEditingController(),cost=TextEditingController();XFile? photo;bool loading=false;
 Future<void> _update(String status)async{setState(()=>loading=true);try{await FirebaseFirestore.instance.collection('orders').doc(widget.id).update({'status':status,'updatedAt':FieldValue.serverTimestamp()});if(mounted)Navigator.pop(context);}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> _pick()async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80);if(f!=null)setState(()=>photo=f);}
 Future<void> _ship()async{if(courier.text.trim().isEmpty||resi.text.trim().isEmpty)return;setState(()=>loading=true);try{String url='';if(photo!=null){final uid=FirebaseAuth.instance.currentUser!.uid;final ref=FirebaseStorage.instance.ref('shipping/'+uid+'/'+widget.id+'.jpg');await ref.putFile(File(photo!.path));url=await ref.getDownloadURL();}await FirebaseFirestore.instance.collection('orders').doc(widget.id).update({'courier':courier.text.trim(),'trackingNumber':resi.text.trim(),'shippingCost':int.tryParse(cost.text)??widget.data['shippingCost']??0,'shippingProofUrl':url,'status':'DIKIRIM','shippedAt':FieldValue.serverTimestamp()});if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>loading=false);}}
 @override Widget build(BuildContext c){final st=(widget.data['status']??'').toString();return Scaffold(appBar:AppBar(title:const Text('Kelola Pesanan')),body:ListView(padding:const EdgeInsets.all(16),children:[Text((widget.data['productName']??'Produk').toString(),style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),Text('Status saat ini: '+st),const SizedBox(height:18),if(st=='DIBAYAR')FilledButton.icon(onPressed:loading?null:()=>_update('DIPROSES'),icon:const Icon(Icons.play_arrow),label:const Text('MULAI PROSES')),if(st=='DIPROSES')FilledButton.icon(onPressed:loading?null:()=>_update('SIAP_DIKIRIM'),icon:const Icon(Icons.inventory_2),label:const Text('SIAP DIKIRIM')),if(['SIAP_DIKIRIM','DIPROSES'].contains(st))...[
 const SizedBox(height:16),const Text('Data pengiriman'),TextField(controller:courier,decoration:const InputDecoration(labelText:'Nama ekspedisi')),TextField(controller:resi,decoration:const InputDecoration(labelText:'Nomor resi')),TextField(controller:cost,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ongkir aktual')),const SizedBox(height:10),OutlinedButton.icon(onPressed:_pick,icon:const Icon(Icons.photo_camera),label:Text(photo==null?'Foto resi/bukti pengiriman':'Foto dipilih')),const SizedBox(height:10),FilledButton.icon(onPressed:loading?null:_ship,icon:const Icon(Icons.local_shipping),label:const Text('SIMPAN & TANDAI DIKIRIM'))]]));}
 @override void dispose(){courier.dispose();resi.dispose();cost.dispose();super.dispose();}
}