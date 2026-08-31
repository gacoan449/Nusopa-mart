const Order = require('../../models/Order');

exports.kirimPesanan = async (req, res) => {
  const { orderId, namaEkspedisi, nomorResi, biayaEkspedisi } = req.body;
  if (!orderId || !namaEkspedisi || !nomorResi || biayaEkspedisi === undefined) return res.status(400).json({ success:false, message:'orderId, namaEkspedisi, nomorResi, dan biayaEkspedisi wajib diisi.' });
  const ongkir = Number(biayaEkspedisi);
  if (!Number.isFinite(ongkir) || ongkir < 0) return res.status(400).json({ success:false, message:'Biaya ekspedisi tidak valid.' });
  try {
    const order = await Order.findOne({ orderId });
    if (!order) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    if (order.sellerId.toString() !== req.user.id.toString()) return res.status(403).json({ success:false, message:'Anda bukan seller pesanan ini.' });
    if (order.statusDana !== 'TERKUNCI') return res.status(400).json({ success:false, message:'Dana Rekber belum terkunci.' });
    if (!['PEMBAYARAN_DIVERIFIKASI','DIPROSES_SELLER'].includes(order.statusPesanan)) return res.status(400).json({ success:false, message:`Pesanan tidak dapat dikirim pada status ${order.statusPesanan}.` });
    if (order.nomorResi) return res.status(400).json({ success:false, message:'Nomor resi sudah tersimpan.' });
    order.namaEkspedisi = String(namaEkspedisi).trim();
    order.nomorResi = String(nomorResi).trim();
    order.biayaEkspedisi = ongkir;
    order.statusPesanan = 'DIKIRIM';
    order.waktuDikirim = new Date();
    await order.save();
    return res.json({ success:true, message:'Data pengiriman berhasil disimpan.', data:{ orderId:order.orderId, namaEkspedisi:order.namaEkspedisi, nomorResi:order.nomorResi, biayaEkspedisi:order.biayaEkspedisi, statusPesanan:order.statusPesanan, statusDana:order.statusDana } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal menyimpan data pengiriman.', error:error.message }); }
};
