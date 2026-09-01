import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final name = TextEditingController();
  final bio = TextEditingController();
  final phone = TextEditingController();
  XFile? avatar;
  XFile? cover;
  bool loading = true;
  bool saving = false;
  Map<String, dynamic> profile = {};

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (uid.isEmpty) return;
    final p = await FirebaseFirestore.instance.collection('social_profiles').doc(uid).get();
    final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    profile = p.data() ?? {};
    final user = u.data() ?? {};
    name.text = (profile['displayName'] ?? user['displayName'] ?? '').toString();
    bio.text = (profile['bio'] ?? '').toString();
    phone.text = (profile['phone'] ?? user['phone'] ?? '').toString();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _pick(bool isCover) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
    if (file == null || !mounted) return;
    setState(() {
      if (isCover) {
        cover = file;
      } else {
        avatar = file;
      }
    });
  }

  Future<String> _upload(XFile file, String folder) async {
    final ref = FirebaseStorage.instance.ref('profiles/$uid/$folder-${DateTime.now().microsecondsSinceEpoch}.jpg');
    await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      var photoUrl = (profile['photoUrl'] ?? '').toString();
      var coverUrl = (profile['coverPhotoUrl'] ?? '').toString();
      if (avatar != null) photoUrl = await _upload(avatar!, 'avatar');
      if (cover != null) coverUrl = await _upload(cover!, 'cover');
      await FirebaseFirestore.instance.collection('social_profiles').doc(uid).set({
        'displayName': name.text.trim(),
        'bio': bio.text.trim(),
        'phone': phone.text.trim(),
        'photoUrl': photoUrl,
        'coverPhotoUrl': coverUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': name.text.trim(),
        'phone': phone.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    ImageProvider<Object>? avatarImage;
    if (avatar != null) {
      avatarImage = FileImage(File(avatar!.path));
    } else if ((profile['photoUrl'] ?? '').toString().isNotEmpty) {
      avatarImage = NetworkImage(profile['photoUrl'].toString());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil'), actions: [IconButton(onPressed: saving ? null : _save, icon: const Icon(Icons.check))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => _pick(true),
            child: SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: cover != null
                    ? Image.file(File(cover!.path), fit: BoxFit.cover)
                    : ((profile['coverPhotoUrl'] ?? '').toString().isEmpty
                        ? Container(color: const Color(0xFFE7EEF9), child: const Center(child: Icon(Icons.add_a_photo_outlined, size: 36)))
                        : Image.network(profile['coverPhotoUrl'].toString(), fit: BoxFit.cover)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => _pick(false),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: avatarImage,
                child: avatarImage == null ? const Icon(Icons.person, size: 44) : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama pengguna', prefixIcon: Icon(Icons.person_outline))),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone_outlined))),
          TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline))),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    phone.dispose();
    super.dispose();
  }
}
