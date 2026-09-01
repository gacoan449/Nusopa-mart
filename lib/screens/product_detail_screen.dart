import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  final Map<String,dynamic> product;
  const ProductDetailScreen({super.key,required this.productId,required this.product});
  static const orange=Color(0xFFFF5722);
  int _i(dynamic v)=>v is int?v:int.tryParse(v.toString())??0;
  @override Widget build(BuildContext context){
    final name=(product['name']??product['productName']??'Produk').toString();
    final image=(product['imageUrl']??product['image']??'').toString();
    final price=_i(product['price']??product['productPrice']);
    final seller=(product['sellerId']??product['ownerId']??'').toString();
    final stock=_i(product['stock']);
    return Scaffold(appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:Text('Detail Produk',style:GoogleFonts.inter(fontWeight:FontWeight.w700))),bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:orange,padding:const EdgeInsets.symmetric(vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),onPressed:seller.isEmpty?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CheckoutScreen(sellerId:seller,productId:productId,productName:name,price:price))),icon:const Icon(Icons.shopping_bag_outlined),label:const Text('BELI DENGAN REKBER')))),body:ListView(children:[AspectRatio(aspectRatio:1,child:image.isEmpty?Container(color:const Color(0xFFF1F2F4),child:const Icon(Icons.image_outlined,size:64,color:Colors.grey)):Image.network(image,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:const Color(0xFFF1F2F4),child:const Icon(Icons.broken_image_outlined,size:64)))),Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:GoogleFonts.inter(fontSize:21,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text('Harga: Rp'+price.toString(),style:GoogleFonts.inter(fontSize:24,fontWeight:FontWeight.w800,color:orange)),const SizedBox(height:14),Row(children:[const Icon(Icons.star_rounded,color:Color(0xFFFFB300)),Text(' '+(product['rating']??'5.0').toString()+'   Terjual '+(product['sold']??0).toString())]),const SizedBox(height:18),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFFEAF7EF),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.shield_outlined,color:Color(0xFF16803A)),SizedBox(width:10),Expanded(child:Text('Rekber Aman — dana mengikuti proses transaksi dan verifikasi yang berlaku.'))])),if(stock>0)...[const SizedBox(height:18),Text('Stok tersedia: '+stock.toString())],const SizedBox(height:22),Text('Deskripsi',style:GoogleFonts.inter(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:8),Text((product['description']??'Belum ada deskripsi produk.').toString(),style:GoogleFonts.inter(height:1.5))]))]));}
}