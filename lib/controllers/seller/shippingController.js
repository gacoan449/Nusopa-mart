const Order = require('../../models/Order');
const Ticket = require('../../models/Ticket');

// Fungsi dipicu ketika kurir/seller mengubah status pesanan menjadi "SELESAI"
exports.selesaikanPesananDanPotongTiket = async (req, res) => {
  const { orderId } = req.body;

  try {
    const pesanan = await Order.findById(orderId);
    if (!pesanan) {
      return res.status(404).json({ success: false, message: 'Data transaksi pesanan tidak ditemukan' });
    }

    // Cek apakah pesanan sudah selesai atau tiket sudah pernah dipotong sebelumnya
    if (pesanan.statusPesanan === 'SELESAI' || pesanan.isTiketDipotong === true) {
      return res.status(400).json({ success: false, message: 'Transaksi ini sudah selesai diproses sebelumnya.' });
    }

    // Ambil data dompet tiket milik seller terkait
    const dompetTiket = await Ticket.findOne({ sellerId: pesanan.sellerId });
    
    // Validasi pencegahan jika tiket seller habis ditengah jalan
    if (!dompetTiket || dompetTiket.sisaTiket < 1) {
      return res.status(403).json({ 
        success: false, 
        message: 'Gagal menyelesaikan orderan. Saldo tiket admin seller habis (0). Harap chat admin untuk isi ulang via QRIS.' 
      });
    }

    // PROSES EKSEKUSI UTAMA:
    dompetTiket.sisaTiket -= 1;     // 1. Potong saldo tiket seller sebanyak 1 tiket
    pesanan.statusPesanan = 'SELESAI'; // 2. Ubah status pesanan pembeli menjadi Selesai
    pesanan.isTiketDipotong = true; // 3. Tandai transaksi agar tidak terpotong dua kali

    // Simpan semua pembaruan perubahan data ke database database
    await dompetTiket.save();
    await pesanan.save();

    return res.status(200).json({
      success: true,
      message: 'Pesanan dinyatakan selesai (COD/Transfer diterima). 1 Tiket admin toko berhasil dipotong otomatis.',
      sisaTiketAktif: dompetTiket.sisaTiket
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
