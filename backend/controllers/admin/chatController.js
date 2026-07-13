const Chat = require('../../models/Chat');

// Fungsi untuk mengirim pesan chat (Bisa teks biasa atau link gambar QRIS manual)
exports.kirimPesanChat = async (req, res) => {
  const { pengirimId, penerimaId, pesanTeks, fileGambarUrl } = req.body;

  try {
    const chatBaru = new Chat({
      pengirimId,
      penerimaId,
      pesanTeks,
      fileGambarUrl // Admin tinggal tempel url foto QRIS di sini saat membalas seller
    });

    await chatBaru.save();

    return res.status(200).json({
      success: true,
      message: 'Pesan chat berhasil dikirim!',
      data: chatBaru
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Fungsi untuk menarik riwayat chat antara Admin dan Seller tertentu
exports.ambilRiwayatChat = async (req, res) => {
  const { pengirimId, penerimaId } = req.params;

  try {
    // Mencari chat dua arah antara admin dan seller terkait
    const riwayat = await Chat.find({
      $or: [
        { pengirimId: pengirimId, penerimaId: penerimaId },
        { pengirimId: penerimaId, penerimaId: pengirimId }
      ]
    }).sort({ waktuKirim: 1 }); // Urutkan dari pesan terlama ke terbaru

    return res.status(200).json({ success: true, data: riwayat });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
