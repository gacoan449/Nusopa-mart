const mongoose = require('mongoose');
const Payment = require('../../models/Payment');
const rekber = require('../rekberController');

exports.kirimBuktiPembayaran = async (req, res) => {
  const buyerId = req.user.id;
  const { orderId, nominalTransfer, buktiTransferUrl } = req.body;
  if (!orderId || nominalTransfer === undefined || !buktiTransferUrl) return res.status(400).json({ success:false, message:'orderId, nominalTransfer, dan buktiTransferUrl wajib diisi.' });
  try {
    const Order = require('../../models/Order');
    const order = await Order.findOne({ orderId });
    if (!order || String(order.buyerId) !== String(buyerId)) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    if (!['MENUNGGU_PEMBAYARAN','DITOLAK'].includes(order.statusPembayaran)) return res.status(409).json({ success:false, message:'Pesanan tidak menerima pembayaran pada status ini.' });
    const nominal = Number(nominalTransfer);
    if (!Number.isSafeInteger(nominal) || nominal !== order.totalPembayaran) return res.status(400).json({ success:false, message:`Nominal transfer harus Rp${order.totalPembayaran.toLocaleString('id-ID')}.` });
    const existing = await Payment.findOne({ orderId:order._id });
    if (existing && existing.status === 'MENUNGGU_VERIFIKASI') return res.status(200).json({ success:true, data:{ paymentId:existing._id, orderId, statusPembayaran:existing.status }, idempotent:true });
    const payment = existing || new Payment({ orderId:order._id, buyerId:order.buyerId, sellerId:order.sellerId, kodePembayaran:order.kodePembayaran, jumlahBarang:order.subtotal, biayaEkspedisi:order.biayaEkspedisi, biayaRekber:order.biayaRekber, totalPembayaran:order.totalPembayaran });
    payment.buktiTransferUrl=buktiTransferUrl; payment.nominalTransfer=nominal; payment.waktuTransfer=new Date(); payment.status='MENUNGGU_VERIFIKASI';
    order.statusPembayaran='MENUNGGU_VERIFIKASI'; order.waktuPembayaran=new Date(); order.buktiPembayaranUrl=buktiTransferUrl;
    await payment.save(); await order.save();
    return res.json({ success:true, message:'Bukti pembayaran menunggu verifikasi Admin.', data:{ paymentId:payment._id, orderId, statusPembayaran:payment.status } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal menyimpan bukti pembayaran.' }); }
};

exports.verifikasiPembayaran = async (req, res) => {
  const { paymentId } = req.body;
  if (!paymentId || !mongoose.Types.ObjectId.isValid(paymentId)) return res.status(400).json({ success:false, message:'paymentId tidak valid.' });
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const payment = await Payment.findById(paymentId).session(session);
    if (!payment || payment.status !== 'MENUNGGU_VERIFIKASI') throw new Error('Pembayaran tidak ditemukan atau sudah diproses.');
    await rekber.verifyPaymentAndLock(payment, req.user.id, session);
    await session.commitTransaction();
    return res.json({ success:true, message:'Pembayaran diverifikasi; dana seller terkunci dan timer 3x24 jam dimulai.', data:{ paymentId, status:'DIVERIFIKASI' } });
  } catch (error) { await session.abortTransaction(); return res.status(409).json({ success:false, message:error.message }); }
  finally { await session.endSession(); }
};

exports.tolakPembayaran = async (req, res) => {
  const { paymentId, catatanAdmin } = req.body;
  if (!paymentId || !mongoose.Types.ObjectId.isValid(paymentId)) return res.status(400).json({ success:false, message:'paymentId tidak valid.' });
  try {
    const Order = require('../../models/Order');
    const payment = await Payment.findOneAndUpdate({ _id:paymentId, status:'MENUNGGU_VERIFIKASI' }, { $set:{ status:'DITOLAK', diverifikasiOleh:req.user.id, waktuVerifikasi:new Date(), catatanAdmin:catatanAdmin || 'Bukti pembayaran ditolak oleh Admin.' } }, { new:true });
    if (!payment) return res.status(409).json({ success:false, message:'Pembayaran tidak ditemukan atau sudah diproses.' });
    await Order.findOneAndUpdate({ _id:payment.orderId, statusPembayaran:'MENUNGGU_VERIFIKASI' }, { $set:{ statusPembayaran:'DITOLAK', statusPesanan:'MENUNGGU_PEMBAYARAN', catatanAdmin:catatanAdmin || 'Bukti pembayaran ditolak oleh Admin.' } });
    return res.json({ success:true, message:'Pembayaran ditolak.', data:{ orderId:payment.orderId, statusPembayaran:payment.status } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal memproses penolakan pembayaran.' }); }
};
