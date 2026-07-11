import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _sedangProses = false;

  // FUNGSI TAMPILKAN DIALOG BUKTI TRANSFER FULLSCREEN (Bisa di-zoom/periksa detail)
  void _bukaPratinjauGambar(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, e, s) => Container(
                  height: 200,
                  color: Colors.white,
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG KONFIRMASI AMAN SEBELUM EKSEKUSI DATA
  void _tampilkanKonfirmasi(BuildContext context, String judul, String pesan, VoidCallback aksiAman) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(pesan, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              aksiAman();
            },
            child: const Text('YA, LANJUTKAN'),
          ),
        ],
      ),
    );
  }

  // SISI BACKEND: Sukses transaksi penambahan tiket ke akun seller
  void _setujuiTiket(BuildContext context, String requestId, String sellerId, int jumlahTiketDiminta) async {
    setState(() => _sedangProses = true);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        DocumentReference requestRef = firestore.collection('topup_tickets').doc(requestId);
        DocumentReference sellerRef = firestore.collection('users').doc(sellerId);

        DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);
        
        // PERBAIKAN 2: Proteksi data bertipe Map aman jika field null / belum ada
        int kuotaSekarang = 0;
        if (sellerSnapshot.exists && sellerSnapshot.data() != null) {
          var sData = sellerSnapshot.data() as Map<String, dynamic>;
          kuotaSekarang = sData['kuota_tiket'] ?? 0;
        }

        transaction.update(requestRef, {'status': 'disetujui'});
        transaction.update(sellerRef, {'kuota_tiket': kuotaSekarang + jumlahTiketDiminta});
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Sukses! Tiket berhasil masuk ke seller.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Gagal: $e')));
      }
    } finally {
      setState(() => _sedangProses = false);
    }
  }

  // SISI BACKEND: Tolak pengajuan tiket palsu
  void _tolakTiket(BuildContext context, String requestId) async {
    setState(() => _sedangProses = true);
    try {
      await FirebaseFirestore.instance.collection('topup_tickets').doc(requestId).update({
        'status': 'ditolak',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan tiket telah ditolak.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
      }
    } finally {
      setState(() => _sedangProses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Verifikasi Tiket Seller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.red.shade900, 
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_sedangProses)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('topup_tickets')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.done_all, size: 40, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 12),
                  const Text('Antrean Bersih!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Tidak ada pengajuan top-up pending saat ini.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var reqId = requests[index].id;
              var data = requests[index].data() as Map<String, dynamic>;
              
              String namaToko = data['nama_toko'] ?? 'Toko Tanpa Nama';
              String paket = data['paket_pilihan'] ?? 'Paket Kustom';
              int jumlahTiket = data['jumlah_tiket_diminta'] ?? 0;
              String buktiUrl = data['bukti_transfer_url'] ?? '';
              String sellerId = data['seller_id'] ?? '';

              return Card(
                elevation: 1.5,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    maintainState: true,
                    initiallyExpanded: true, // Otomatis membuka isi card utama
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: Icon(Icons.confirmation_number_outlined, color: Colors.orange.shade800, size: 20),
                    ),
                    title: Text(namaToko, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('$paket • ($jumlahTiket Tiket)', style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 10),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(Icons.image_search, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Bukti Pembayaran (Klik Gambar Untuk Zoom):', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // PERBAIKAN 1: Gambar Pratinjau Interaktif Kompak
                            GestureDetector(
                              onTap: () => _bukaPratinjauGambar(context, buktiUrl),
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
