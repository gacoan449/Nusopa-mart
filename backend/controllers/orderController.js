const mongoose = require('mongoose');
const Order = require('../models/Order');
const Wallet = require('../models/Wallet');

const BIAYA_REKBER = 3000;

/*
|--------------------------------------------------------------------------
| GENERATE ORDER ID
|--------------------------------------------------------------------------
*/
function generateOrderId() {
  const waktu = Date.now().toString().slice(-10);
  const acak = Math.floor(100 + Math.random() * 900);

  return `NSP-${waktu}-${acak}`;
}

/*
|--------------------------------------------------------------------------
| GENERATE KODE PEMBAYARAN
|--------------------------------------------------------------------------
*/
function generateKodePembayaran() {
  const waktu = Date.now().toString().slice(-8);
  const acak = Math.floor(100 + Math.random() * 900);

  return `PAY-${waktu}-${acak}`;
}

/*
|--------------------------------------------------------------------------
| MEMBUAT PESANAN
|--------------------------------------------------------------------------
|
| Alur:
|
| Buyer checkout
|      ↓
| Order dibuat
|      ↓
| MENUNGGU_PEMBAYARAN
|      ↓
| Buyer transfer ke Admin
|
|--------------------------------------------------------------------------
*/
exports.buatPesanan = async (req, res) => {
  const {
    buyerId,
    sellerId,
    namaProduk,
    jumlah,
    hargaProduk,
    biayaEkspedisi,
  } = req.body;

  if (
    !buyerId ||
    !sellerId ||
    !namaProduk ||
    jumlah === undefined ||
    hargaProduk === undefined
  ) {
    return res.status(400).json({
      success: false,
      message:
        'buyerId, sellerId, namaProduk, jumlah, dan hargaProduk wajib diisi.',
    });
  }

  if (
    !mongoose.Types.ObjectId.isValid(buyerId) ||
    !mongoose.Types.ObjectId.isValid(sellerId)
  ) {
    return res.status(400).json({
      success: false,
      message: 'buyerId atau sellerId tidak valid.',
    });
  }

  const qty = Number(jumlah);
  const harga = Number(hargaProduk);
  const ongkir =
    biayaEkspedisi === undefined || biayaEkspedisi === null
      ? 0
      : Number(biayaEkspedisi);

  if (!Number.isInteger(qty) || qty < 1) {
    return res.status(400).json({
      success: false,
      message: 'Jumlah produk tidak valid.',
    });
  }

  if (!Number.isFinite(harga) || harga < 0) {
    return res.status(400).json({
      success: false,
      message: 'Harga produk tidak valid.',
    });
  }

  if (!Number.isFinite(ongkir) || ongkir < 0) {
    return res.status(400).json({
      success: false,
      message: 'Biaya ekspedisi tidak valid.',
    });
  }

  try {
    const subtotal = qty * harga;

    const totalPembayaran =
      subtotal +
      ongkir +
      BIAYA_REKBER;

    const order = new Order({
      orderId: generateOrderId(),

      buyerId,
      sellerId,

      namaProduk: namaProduk.trim(),

      jumlah: qty,
      hargaProduk: harga,
      subtotal,

      biayaEkspedisi: ongkir,

      biayaRekber: BIAYA_REKBER,

      totalPembayaran,

      metodePembayaran: 'TRANSFER_REKBER',

      statusPembayaran: 'MENUNGGU_PEMBAYARAN',

      statusPesanan: 'MENUNGGU_PEMBAYARAN',

      statusDana: 'BELUM_DIBAYAR',

      danaSeller: subtotal,

      kodePembayaran: generateKodePembayaran(),
    });

    await order.save();

    return res.status(201).json({
      success: true,
      message: 'Pesanan berhasil dibuat.',
      data: {
        orderId: order.orderId,
        kodePembayaran: order.kodePembayaran,

        subtotal: order.subtotal,
        biayaEkspedisi: order.biayaEkspedisi,
        biayaRekber: order.biayaRekber,
        totalPembayaran: order.totalPembayaran,

        statusPembayaran: order.statusPembayaran,
        statusPesanan: order.statusPesanan,
        statusDana: order.statusDana,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal membuat pesanan.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| BUYER MELIHAT PESANANNYA
|--------------------------------------------------------------------------
*/
exports.ambilPesananBuyer = async (req, res) => {
  const { buyerId } = req.params;

  if (!buyerId || !mongoose.Types.ObjectId.isValid(buyerId)) {
    return res.status(400).json({
      success: false,
      message: 'buyerId tidak valid.',
    });
  }

  try {
    const orders = await Order.find({
      buyerId,
    }).sort({
      createdAt: -1,
    });

    return res.status(200).json({
      success: true,
      total: orders.length,
      data: orders,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil pesanan buyer.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| SELLER MELIHAT PESANAN
|--------------------------------------------------------------------------
*/
exports.ambilPesananSeller = async (req, res) => {
  const { sellerId } = req.params;

  if (!sellerId || !mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  try {
    const orders = await Order.find({
      sellerId,
    }).sort({
      createdAt: -1,
    });

    return res.status(200).json({
      success: true,
      total: orders.length,
      data: orders,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil pesanan seller.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| DETAIL PESANAN
|--------------------------------------------------------------------------
*/
exports.ambilDetailPesanan = async (req, res) => {
  const { orderId } = req.params;

  if (!orderId) {
    return res.status(400).json({
      success: false,
      message: 'orderId wajib diisi.',
    });
  }

  try {
    const order = await Order.findOne({
      orderId,
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.',
      });
    }

    return res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil detail pesanan.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| BUYER KONFIRMASI BARANG DITERIMA
|--------------------------------------------------------------------------
|
| Dana:
|
| Wallet.saldoTerkunci
|          ↓
| Wallet.saldoTersedia
|
| Order:
|
| TERKUNCI
|    ↓
| TERSEDIA
|
|--------------------------------------------------------------------------
*/
exports.konfirmasiBarangDiterima = async (req, res) => {
  const {
    orderId,
    buyerId,
  } = req.body;

  if (!orderId || !buyerId) {
    return res.status(400).json({
      success: false,
      message: 'orderId dan buyerId wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(buyerId)) {
    return res.status(400).json({
      success: false,
      message: 'buyerId tidak valid.',
    });
  }

  const session = await mongoose.startSession();

  try {
    session.startTransaction();

    const order = await Order.findOne({
      orderId,
    }).session(session);

    if (!order) {
      throw new Error('Pesanan tidak ditemukan.');
    }

    if (order.buyerId.toString() !== buyerId.toString()) {
      throw new Error(
        'Anda bukan buyer dari pesanan ini.'
      );
    }

    if (order.statusDana !== 'TERKUNCI') {
      throw new Error(
        `Dana tidak dapat dicairkan. Status dana saat ini: ${order.statusDana}.`
      );
    }

    if (
      ![
        'DIKIRIM',
        'DITERIMA',
      ].includes(order.statusPesanan)
    ) {
      throw new Error(
        `Pesanan belum dapat diselesaikan. Status saat ini: ${order.statusPesanan}.`
      );
    }

    const wallet = await Wallet.findOne({
      sellerId: order.sellerId,
    }).session(session);

    if (!wallet) {
      throw new Error(
        'Wallet seller tidak ditemukan.'
      );
    }

    if (wallet.statusWallet !== 'AKTIF') {
      throw new Error(
        'Wallet seller sedang dibekukan.'
      );
    }

    const danaSeller = Number(order.danaSeller);

    if (
      !Number.isFinite(danaSeller) ||
      danaSeller < 0
    ) {
      throw new Error(
        'Nominal dana seller tidak valid.'
      );
    }

    if (wallet.saldoTerkunci < danaSeller) {
      throw new Error(
        'Saldo terkunci seller tidak mencukupi.'
      );
    }

    /*
     * PINDAHKAN DANA:
     *
     * TERKUNCI → TERSEDIA
     */
    wallet.saldoTerkunci -= danaSeller;
    wallet.saldoTersedia += danaSeller;

    order.statusPesanan = 'SELESAI';
    order.statusDana = 'TERSEDIA';
    order.waktuDiterima = new Date();
    order.waktuSelesai = new Date();

    await wallet.save({
      session,
    });

    await order.save({
      session,
    });

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message:
        'Pesanan selesai. Dana seller sekarang tersedia untuk ditarik.',
      data: {
        orderId: order.orderId,
        danaSeller,
        statusPesanan: order.statusPesanan,
        statusDana: order.statusDana,
        saldoTersedia: wallet.saldoTersedia,
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
