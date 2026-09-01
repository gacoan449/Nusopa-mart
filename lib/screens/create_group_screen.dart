import 'package:flutter/material.dart';
import '../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final name = TextEditingController();
  String privacy = 'Publik';
  bool saving = false;

  Future<void> create() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final id = await GroupService.instance.createGroup(name: name.text, privacy: privacy);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat grup: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat Grup')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Buat komunitas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Bangun ruang komunitas berdasarkan hobi, minat, atau kategori jual beli.'),
      const SizedBox(height: 24),
      TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama grup', hintText: 'Contoh: Komunitas Gadget Bekas')),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(initialValue: privacy, decoration: const InputDecoration(labelText: 'Privasi'), items: const [DropdownMenuItem(value: 'Publik', child: Text('Publik')), DropdownMenuItem(value: 'Privat', child: Text('Privat'))], onChanged: saving ? null : (v) => setState(() => privacy = v ?? 'Publik')),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: saving ? null : create, icon: const Icon(Icons.groups_rounded), label: Text(saving ? 'Membuat...' : 'Buat Grup')),
    ]),
  );

  @override void dispose() { name.dispose(); super.dispose(); }
}
