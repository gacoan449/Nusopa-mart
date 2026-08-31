const mongoose = require('mongoose');
const Order = require('../models/Order');
const Wallet = require('../models/Wallet');

const BIAYA_REKBER = 3000;

const makeId = (prefix) => `${prefix}-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;

exports.buatPesanan = async (req, res) => {
  const buyerId = req.user.id;
  const { sellerId, namaProduk, jumlah, hargaProduk, biayaEkspedisi = 0 } = req.body;

  if (!sellerId || !namaProduk || jumlah === undefined || hargaProduk === undefined) return res.status(400).json({ success:false, message:'sellerId, namaProduk, jumlah, dan hargaProduk wajib diisi.' });
  if (!mongoose.Types.ObjectId.isValid(sellerId)) return res.status(400).json({ success:false, message:'sellerId tidak valid.' });

  const qty = Number(jumlah), harga = Number(hargaProduk), ongkir = Number(biayaEkspedisi);
  if (!Number.isInteger(qty) || qty < 1) return res.status(400).json({ success:false, message:'Jumlah produk tidak valid.' });
  if (!Number.isFinite(harga) || harga < 0 || !Number.isFinite(ongkir) || ongkir < 0) return res.status(400).json({ success:false, message:'Harga atau biaya ekspedisi tidak valid.' });

  try {
    const subtotal = qty * harga;
    const order = await Order.create({
      orderId: makeId('NSP'), buyerId, sellerId, namaProduk:String(namaProduk).trim(), jumlah:qty,
      hargaProduk:harga, subtotal, biayaEkspedisi:ongkir, biayaRekber:BIAYA_REKBER,
      totalPembayaran:subtotal + ongkir + BIAYA_REKBER, metodePembayaran:'TRANSFER_REKBER',
      statusPembayaran:'MENUNGGU_PEMBAYARAN', statusPesanan:'MENUNGGU_PEMBAYARAN',
      statusDana:'BELUM_DIBAYAR', danaSeller:subtotal, kodePembayaran:makeId('PAY')
    });
    return res.status(201).json({ success:true, message:'Pesanan berhasil dibuat.', data:order });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal membuat pesanan.', error:error.message }); }
};

exports.ambilPesananBuyer = async (req, res) => {
  try { const orders = await Order.find({ buyerId:req.user.id }).sort({ createdAt:-1 }); return res.json({ success:true, total:orders.length, data:orders }); }
  catch (error) { return res.status(500).json({ success:false, message:'Gagal mengambil pesanan buyer.', error:error.message }); }
};

exports.ambilPesananSeller = async (req, res) => {
  try { const orders = await Order.find({ sellerId:req.user.id }).sort({ createdAt:-1 }); return res.json({ success:true, total:orders.length, data:orders }); }
  catch (error) { return res.status(500).json({ success:false, message:'Gagal mengambil pesanan seller.', error:error.message }); }
};

exports.ambilDetailPesanan = async (req, res) => {
  try {
    const order = await Order.findOne({ orderId:req.params.orderId });
    if (!order) return res.status(404).json({ success:false, message:'Pesanan tidak ditemukan.' });
    const id = req.user.id.toString();
    if (req.user.role !== 'ADMIN' && order.buyerId.toString() !== id && order.sellerId.toString() !== id) return res.status(403).json({ success:false, message:'Anda tidak memiliki akses ke pesanan ini.' });
    return res.json({ success:true, data:order });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal mengambil detail pesanan.', error:error.message }); }
};

exports.konfirmasiBarangDiterima = async (req, res) => {
  const { orderId } = req.body;
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const order = await Order.findOne({ orderId }).session(session);
    if (!order) throw new Error('Pesanan tidak ditemukan.');
    if (order.buyerId.toString() !== req.user.id.toString()) throw new Error('Anda bukan buyer dari pesanan ini.');
    if (order.statusDana !== 'TERKUNCI') throw new Error(`Dana tidak dapat dicairkan. Status: ${order.statusDana}.`);
    if (!['DIKIRIM','DITERIMA'].includes(order.statusPesanan)) throw new Error(`Pesanan belum dapat diselesaikan. Status: ${order.statusPesanan}.`);

    const wallet = await Wallet.findOne({ sellerId:order.sellerId }).session(session);
    if (!wallet) throw new Error('Wallet seller tidak ditemukan.');
    if (wallet.statusWallet !== 'AKTIF') throw new Error('Wallet seller sedang dibekukan.');
    const dana = Number(order.danaSeller);
    if (!Number.isFinite(dana) || dana < 0 || wallet.saldoTerkunci < dana) throw new Error('Saldo Rekber seller tidak valid atau tidak mencukupi.');

    wallet.saldoTerkunci -= dana;
    wallet.saldoTersedia += dana;
    order.statusPesanan = 'SELESAI';
    order.statusDana = 'TERSEDIA';
    order.waktuDiterima = new Date();
    order.waktuSelesai = new Date();

    await wallet.save({ session });
    await order.save({ session });
    await session.commitTransaction();
    return res.json({ success:true, message:'Pesanan selesai. Dana seller tersedia untuk ditarik.', data:{ orderId:order.orderId, danaSeller:dana, statusDana:order.statusDana, saldoTersedia:wallet.saldoTersedia } });
  } catch (error) {
    await session.abortTransaction();
    return res.status(400).json({ success:false, message:error.message });
  } finally { await session.endSession(); }
};
