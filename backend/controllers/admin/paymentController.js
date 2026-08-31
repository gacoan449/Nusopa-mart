const mongoose = require('mongoose');
const Payment = require('../../models/Payment');
const Order = require('../../models/Order');
const Wallet = require('../../models/Wallet');

/*
|--------------------------------------------------------------------------
| 1. BUYER MENGIRIM BUKTI PEMBAYARAN
|--------------------------------------------------------------------------
*/
exports.kirimBuktiPembayaran = async (req, res) => {
  const {
    orderId,
    buyerId,
    nominalTransfer,
    buktiTransferUrl,
  } = req.body;

  if (!orderId || !buyerId || !nominalTransfer || !buktiTransferUrl) {
    return res.status(400).json({
      success: false,
      message: 'orderId, buyerId, nominalTransfer, dan buktiTransferUrl wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(buyerId)) {
    return res.status(400).json({
      success: false,
      message: 'buyerId tidak valid.',
    });
  }

  try {
    const order = await Order.findOne({ orderId });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.',
      });
    }

    if (order.buyerId.toString() !== buyerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses ke pesanan ini.',
      });
    }

    if (
      ![
        'MENUNGGU_PEMBAYARAN',
        'MENUNGGU_VERIFIKASI',
      ].includes(order.statusPembayaran)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Pesanan tidak dapat menerima bukti pembayaran pada status saat ini.',
      });
    }

    const nominal = Number(nominalTransfer);

    if (!Number.isFinite(nominal) || nominal <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Nominal transfer tidak valid.',
      });
    }

    if (nominal !== Number(order.totalPembayaran)) {
      return res.status(400).json({
        success: false,
        message: `Nominal transfer harus Rp${Number(order.totalPembayaran).toLocaleString('id-ID')}.`,
      });
    }

    let payment = await Payment.findOne({ orderId: order._id });

    if (!payment) {
      payment = new Payment({
        orderId: order._id,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        kodePembayaran: order.kodePembayaran,
        jumlahBarang: order.subtotal,
        biayaEkspedisi: order.biayaEkspedisi,
        biayaRekber: order.biayaRekber,
        totalPembayaran: order.totalPembayaran,
      });
    }

    payment.buktiTransferUrl = buktiTransferUrl;
    payment.nominalTransfer = nominal;
    payment.waktuTransfer = new Date();
    payment.status = 'MENUNGGU_VERIFIKASI';

    await payment.save();

    order.statusPembayaran = 'MENUNGGU_VERIFIKASI';
    order.statusPesanan = 'MENUNGGU_PEMBAYARAN';
    order.waktuPembayaran = new Date();

    await order.save();

    return res.status(200).json({
      success: true,
      message: 'Bukti pembayaran berhasil dikirim dan menunggu verifikasi Admin.',
      data: {
        paymentId: payment._id,
        orderId: order.orderId,
        statusPembayaran: payment.status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal menyimpan bukti pembayaran.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| 2. ADMIN VERIFIKASI PEMBAYARAN
|--------------------------------------------------------------------------
| Setelah disetujui:
| - Payment -> DIVERIFIKASI
| - Order -> PEMBAYARAN_DIVERIFIKASI
| - Dana seller -> TERKUNCI
| - Wallet seller -> saldoTerkunci bertambah
|--------------------------------------------------------------------------
*/
exports.verifikasiPembayaran = async (req, res) => {
  const {
    paymentId,
    adminId,
  } = req.body;

  if (!paymentId || !adminId) {
    return res.status(400).json({
      success: false,
      message: 'paymentId dan adminId wajib diisi.',
    });
  }

  if (
    !mongoose.Types.ObjectId.isValid(paymentId) ||
    !mongoose.Types.ObjectId.isValid(adminId)
  ) {
    return res.status(400).json({
      success: false,
      message: 'paymentId atau adminId tidak valid.',
    });
  }

  const session = await mongoose.startSession();

  try {
    session.startTransaction();

    const payment = await Payment.findById(paymentId).session(session);

    if (!payment) {
      throw new Error('Data pembayaran tidak ditemukan.');
    }

    if (payment.status !== 'MENUNGGU_VERIFIKASI') {
      throw new Error(
        `Pembayaran tidak dapat diverifikasi. Status saat ini: ${payment.status}.`
      );
    }

    const order = await Order.findById(payment.orderId).session(session);

    if (!order) {
      throw new Error('Pesanan terkait pembayaran tidak ditemukan.');
    }

    if (order.statusDana === 'TERKUNCI') {
      throw new Error('Dana pesanan sudah masuk Rekber sebelumnya.');
    }

    if (order.statusDana === 'TERSEDIA') {
      throw new Error('Dana pesanan sudah pernah tersedia untuk seller.');
    }

    /*
     * Dana milik seller = subtotal produk.
     * Biaya Rekber Rp3.000 bukan hak seller.
     * Ongkir merupakan komponen pengiriman.
     */
    const danaSeller = Number(order.subtotal);

    if (!Number.isFinite(danaSeller) || danaSeller < 0) {
      throw new Error('Nilai dana seller pada order tidak valid.');
    }

    let wallet = await Wallet.findOne({
      sellerId: order.sellerId,
    }).session(session);

    if (!wallet) {
      wallet = new Wallet({
        sellerId: order.sellerId,
        saldoTerkunci: 0,
        saldoTersedia: 0,
        totalDitarik: 0,
        statusWallet: 'AKTIF',
      });
    }

    if (wallet.statusWallet !== 'AKTIF') {
      throw new Error('Wallet seller sedang dibekukan.');
    }

    wallet.saldoTerkunci += danaSeller;

    payment.status = 'DIVERIFIKASI';
    payment.diverifikasiOleh = adminId;
    payment.waktuVerifikasi = new Date();

    order.statusPembayaran = 'DIVERIFIKASI';
    order.statusPesanan = 'PEMBAYARAN_DIVERIFIKASI';
    order.statusDana = 'TERKUNCI';
    order.danaSeller = danaSeller;
    order.waktuVerifikasi = new Date();

    await wallet.save({ session });
    await payment.save({ session });
    await order.save({ session });

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message: 'Pembayaran diverifikasi. Dana seller berhasil dikunci dalam Rekber.',
      data: {
        orderId: order.orderId,
        paymentId: payment._id,
        danaTerkunci: danaSeller,
        statusDana: order.statusDana,
        statusOrder: order.statusPesanan,
      },
    });
  } catch (error) {
    await session.abortTransaction();

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  } finally {
    await session.endSession();
  }
};

/*
|--------------------------------------------------------------------------
| 3. ADMIN MENOLAK PEMBAYARAN
|--------------------------------------------------------------------------
*/
exports.tolakPembayaran = async (req, res) => {
  const {
    paymentId,
    adminId,
    catatanAdmin,
  } = req.body;

  if (!paymentId || !adminId) {
    return res.status(400).json({
      success: false,
      message: 'paymentId dan adminId wajib diisi.',
    });
  }

  if (
    !mongoose.Types.ObjectId.isValid(paymentId) ||
    !mongoose.Types.ObjectId.isValid(adminId)
  ) {
    return res.status(400).json({
      success: false,
      message: 'paymentId atau adminId tidak valid.',
    });
  }

  try {
    const payment = await Payment.findById(paymentId);

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Data pembayaran tidak ditemukan.',
      });
    }

    if (payment.status !== 'MENUNGGU_VERIFIKASI') {
      return res.status(400).json({
        success: false,
        message: `Pembayaran tidak dapat ditolak. Status saat ini: ${payment.status}.`,
      });
    }

    const order = await Order.findById(payment.orderId);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan terkait tidak ditemukan.',
      });
    }

    payment.status = 'DITOLAK';
    payment.diverifikasiOleh = adminId;
    payment.waktuVerifikasi = new Date();
    payment.catatanAdmin = catatanAdmin || 'Pembayaran ditolak oleh Admin.';

    order.statusPembayaran = 'DITOLAK';
    order.statusPesanan = 'MENUNGGU_PEMBAYARAN';
    order.catatanAdmin =
      catatanAdmin || 'Bukti pembayaran ditolak oleh Admin.';

    await payment.save();
    await order.save();

    return res.status(200).json({
      success: true,
      message: 'Pembayaran ditolak.',
      data: {
        orderId: order.orderId,
        statusPembayaran: payment.status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses penolakan pembayaran.',
      error: error.message,
    });
  }
};
