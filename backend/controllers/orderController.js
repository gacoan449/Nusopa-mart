const rekber = require('./rekberController');

exports.buatPesanan = rekber.createOrder;
exports.ambilPesananBuyer = async (req, res) => { req.query.role = 'buyer'; return rekber.listMine(req, res); };
exports.ambilPesananSeller = async (req, res) => { req.query.role = 'seller'; return rekber.listMine(req, res); };
exports.ambilDetailPesanan = async (req, res) => {
  const Order = require('../models/Order');
  try {
    const order = await Order.findOne({ orderId:req.params.orderId }).lean();
    if (!order) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    const id = String(req.user.id);
    if (req.user.role !== 'ADMIN' && String(order.buyerId) !== id && String(order.sellerId) !== id) return res.status(403).json({ success:false, message:'Anda tidak memiliki akses ke pesanan ini.' });
    return res.json({ success:true, data:order });
  } catch (_) { return res.status(500).json({ success:false, message:'Gagal mengambil detail pesanan.' }); }
};
exports.konfirmasiBarangDiterima = rekber.confirmReceived;
exports.autoRelease = rekber.autoRelease;
exports.buatUlasan = rekber.createReview;
