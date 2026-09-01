import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/direct_chat_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inbox')),
    body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: DirectChatService.instance.inbox(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Inbox tidak dapat dimuat: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = [...snap.data!.docs]..sort((a,b) {
          final aa=a.data()['updatedAt']; final bb=b.data()['updatedAt'];
          return ((bb is Timestamp)?bb.millisecondsSinceEpoch:0).compareTo((aa is Timestamp)?aa.millisecondsSinceEpoch:0);
        });
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada percakapan. Buka profil pengguna untuk memulai chat.', textAlign: TextAlign.center)));
        return ListView.separated(itemCount: docs.length, separatorBuilder: (_,__) => const Divider(height:1), itemBuilder:(context,i) {
          final d=docs[i].data(); final p=List<String>.from(d['participants']??[]);
          final other=p.firstWhere((x)=>x!=DirectChatService.instance.uid,orElse:()=>DirectChatService.instance.uid);
          final counts=Map<String,dynamic>.from(d['unreadCounts']??{}); final unread=(counts[DirectChatService.instance.uid] as num? ?? 0).toInt();
          return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future:DirectChatService.instance.profile(other),builder:(context,user){
            final u=user.data?.data()??{}; final name=(u['name']??u['displayName']??'Pengguna').toString();
            return ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:6),leading:CircleAvatar(radius:27,child:Text(name.isNotEmpty?name[0].toUpperCase():'?')),title:Row(children:[Expanded(child:Text(name,style:TextStyle(fontWeight:unread>0?FontWeight.w800:FontWeight.w600))),if(unread>0)Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(20)),child:Text('$unread',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold)))]),subtitle:Text((d['lastMessage']??'Mulai percakapan').toString(),maxLines:1,overflow:TextOverflow.ellipsis),onTap:()async{await DirectChatService.instance.markRead(d.id);if(context.mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(chatId:d.id,otherUid:other,name:name)));});
          });
        });
      },
    ),
  );
}
