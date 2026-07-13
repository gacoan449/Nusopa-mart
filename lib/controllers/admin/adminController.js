const Ticket = require('../../models/Ticket');

// Fungsi admin menambah 10 tiket manual setelah verifikasi pembayaran QRIS sukses
exports.tambahTiketSellerManual = async (req, res) => {
  const { sellerId, jumlahTopUp } = req.body; // Misal jumlahTopUp = 10

  try {
    // Cari data dompet tiket milik seller tersebut
    let dompetTiket = await Ticket.findOne({ sellerId });

    if (!dompetTiket) {
      // Jika dompet belum ada, buat baru
      dompetTiket = new Ticket({ sellerId, sisaTiket: 0 });
    }

    // Tambahkan jumlah tiket baru ke saldo aktif seller
    dompetTiket.sisaTiket += parseInt(jumlahTopUp);
    
    // Catat riwayat transaksi sukses di sistem backend
    dompetTiket.riwayatPembelian.push({
      jumlahTiket: jumlahTopUp,
      statusVerifikasi: 'SUKSES'
    });

    await dompetTiket.save();

    return res.status(200).json({
      success: true,
      message: `Berhasil menambahkan ${jumlahTopUp} tiket ke Seller. Saldo aktif sekarang: ${dompetTiket.sisaTiket} tiket.`
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
