const mongoose = require('mongoose');
const Payment = require('../../models/Payment');
const Order = require('../../models/Order');
const Wallet = require('../../models/Wallet');

exports.kirimBuktiPembayaran = async (req, res) => {
  const buyerId = req.user.id;
  const { orderId, nominalTransfer, buktiTransferUrl } = req.body;
  if (!orderId || nominalTransfer === undefined || !buktiTransferUrl) return res.status(400).json({ success:false, message:'orderId, nominalTransfer, dan buktiTransferUrl wajib diisi.' });
  try {
    const order = await Order.findOne({ orderId });
    if (!order) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    if (order.buyerId.toString() !== buyerId.toString()) return res.status(403).json({ success:false, message:'Anda tidak memiliki akses ke pesanan ini.' });
    if (!['MENUNGGU_PEMBAYARAN','MENUNGGU_VERIFIKASI'].includes(order.statusPembayaran)) return res.status(400).json({ success:false, message:'Pesanan tidak dapat menerima bukti pembayaran pada status saat ini.' });
    const nominal = Number(nominalTransfer);
    if (!Number.isFinite(nominal) || nominal !== Number(order.totalPembayaran)) return res.status(400).json({ success:false, message:`Nominal transfer harus Rp${Number(order.totalPembayaran).toLocaleString('id-ID')}.` });
    let payment = await Payment.findOne({ orderId:order._id });
    if (!payment) payment = new Payment({ orderId:order._id, buyerId:order.buyerId, sellerId:order.sellerId, kodePembayaran:order.kodePembayaran, jumlahBarang:order.subtotal, biayaEkspedisi:order.biayaEkspedisi, biayaRekber:order.biayaRekber, totalPembayaran:order.totalPembayaran });
    payment.buktiTransferUrl = buktiTransferUrl;
    payment.nominalTransfer = nominal;
    payment.waktuTransfer = new Date();
    payment.status = 'MENUNGGU_VERIFIKASI';
    order.statusPembayaran = 'MENUNGGU_VERIFIKASI';
    order.statusPesanan = 'MENUNGGU_PEMBAYARAN';
    order.waktuPembayaran = new Date();
    order.buktiPembayaranUrl = buktiTransferUrl;
    await payment.save(); await order.save();
    return res.json({ success:true, message:'Bukti pembayaran berhasil dikirim dan menunggu verifikasi Admin.', data:{ paymentId:payment._id, orderId:order.orderId, statusPembayaran:payment.status } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal menyimpan bukti pembayaran.', error:error.message }); }
};

exports.verifikasiPembayaran = async (req, res) => {
  const { paymentId } = req.body;
  const adminId = req.user.id;
  if (!paymentId || !mongoose.Types.ObjectId.isValid(paymentId)) return res.status(400).json({ success:false, message:'paymentId tidak valid.' });
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const payment = await Payment.findById(paymentId).session(session);
    if (!payment || payment.status !== 'MENUNGGU_VERIFIKASI') throw new Error('Pembayaran tidak ditemukan atau sudah diproses.');
    const order = await Order.findById(payment.orderId).session(session);
    if (!order || ['TERKUNCI','TERSEDIA'].includes(order.statusDana)) throw new Error('Status dana pesanan tidak memungkinkan verifikasi.');
    const danaSeller = Number(order.subtotal);
    let wallet = await Wallet.findOne({ sellerId:order.sellerId }).session(session);
    if (!wallet) wallet = new Wallet({ sellerId:order.sellerId, saldoTerkunci:0, saldoTersedia:0, totalDitarik:0, statusWallet:'AKTIF' });
    if (wallet.statusWallet !== 'AKTIF') throw new Error('Wallet seller sedang dibekukan.');
    wallet.saldoTerkunci += danaSeller;
    payment.status = 'DIVERIFIKASI'; payment.diverifikasiOleh = adminId; payment.waktuVerifikasi = new Date();
    order.statusPembayaran = 'DIVERIFIKASI'; order.statusPesanan = 'PEMBAYARAN_DIVERIFIKASI'; order.statusDana = 'TERKUNCI'; order.danaSeller = danaSeller; order.waktuVerifikasi = new Date();
    await wallet.save({session}); await payment.save({session}); await order.save({session}); await session.commitTransaction();
    return res.json({ success:true, message:'Pembayaran diverifikasi dan dana seller terkunci.', data:{ orderId:order.orderId, paymentId:payment._id, danaTerkunci:danaSeller, statusDana:order.statusDana } });
  } catch (error) { await session.abortTransaction(); return res.status(400).json({ success:false, message:error.message }); }
  finally { await session.endSession(); }
};

exports.tolakPembayaran = async (req, res) => {
  const { paymentId, catatanAdmin } = req.body;
  const adminId = req.user.id;
  if (!paymentId || !mongoose.Types.ObjectId.isValid(paymentId)) return res.status(400).json({ success:false, message:'paymentId tidak valid.' });
  try {
    const payment = await Payment.findById(paymentId); if (!payment) return res.status(404).json({ success:false, message:'Data pembayaran tidak ditemukan.' });
    if (payment.status !== 'MENUNGGU_VERIFIKASI') return res.status(400).json({ success:false, message:`Status pembayaran ${payment.status} tidak dapat ditolak.` });
    const order = await Order.findById(payment.orderId); if (!order) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    payment.status='DITOLAK'; payment.diverifikasiOleh=adminId; payment.waktuVerifikasi=new Date(); payment.catatanAdmin=catatanAdmin || 'Pembayaran ditolak oleh Admin.';
    order.statusPembayaran='DITOLAK'; order.statusPesanan='MENUNGGU_PEMBAYARAN'; order.catatanAdmin=catatanAdmin || 'Bukti pembayaran ditolak oleh Admin.';
    await payment.save(); await order.save();
    return res.json({ success:true, message:'Pembayaran ditolak.', data:{ orderId:order.orderId, statusPembayaran:payment.status } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal memproses penolakan pembayaran.', error:error.message }); }
};
