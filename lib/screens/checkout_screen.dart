import 'package:flutter/material.dart';
import '../services/rekber_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String sellerId, productId, productName;
  final int price;
  const CheckoutScreen({super.key,required this.sellerId,required this.productId,required this.productName,required this.price});
  @override State<CheckoutScreen> createState()=>_CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen>{
  int qty=1; final shipping=TextEditingController(text:'0'); bool loading=false;
  Future<void> submit() async { final s=int.tryParse(shipping.text)??0; if(s<0)return; setState(()=>loading=true); try{final id=await RekberService.instance.createOrder(sellerId:widget.sellerId,productId:widget.productId,productName:widget.productName,price:widget.price,qty:qty,shippingCost:s); if(mounted)showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Order dibuat'),content:Text('ID Order: $id\nTotal termasuk biaya Rekber Rp3.000.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))]));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal: $e')));}finally{if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Checkout')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(widget.productName,style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),Text('Harga: Rp${widget.price}'),Row(children:[const Text('Jumlah'),IconButton(onPressed:qty>1?()=>setState(()=>qty--):null,icon:const Icon(Icons.remove)),Text('$qty'),IconButton(onPressed:()=>setState(()=>qty++),icon:const Icon(Icons.add))]),TextField(controller:shipping,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Biaya ekspedisi',prefixText:'Rp ',border:OutlineInputBorder())),const SizedBox(height:12),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Biaya Rekber: Rp3.000\nPembayaran dilakukan manual ke rekening Admin setelah order dibuat.'))),const SizedBox(height:20),FilledButton(onPressed:loading?null:submit,child:Text(loading?'Memproses...':'BUAT ORDER'))]));
  @override void dispose(){shipping.dispose();super.dispose();}
}
