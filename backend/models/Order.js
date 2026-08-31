const mongoose = require('mongoose');

const OrderSchema = new mongoose.Schema(
  {
    // =========================
    // IDENTITAS TRANSAKSI
    // =========================
    orderId: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    buyerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // =========================
    // PRODUK
    // =========================
    namaProduk: {
      type: String,
      required: true,
      trim: true,
    },

    jumlah: {
      type: Number,
      required: true,
      min: 1,
      default: 1,
    },

    hargaProduk: {
      type: Number,
      required: true,
      min: 0,
    },

    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },

    // =========================
    // PENGIRIMAN
    // =========================
    namaEkspedisi: {
      type: String,
      trim: true,
      default: null,
    },

    nomorResi: {
      type: String,
      trim: true,
      default: null,
    },

    biayaEkspedisi: {
      type: Number,
      min: 0,
      default: 0,
    },

    // =========================
    // BIAYA REKBER
    // Dibayar oleh buyer
    // =========================
    biayaRekber: {
      type: Number,
      required: true,
      min: 0,
      default: 3000,
    },

    // =========================
    // TOTAL PEMBAYARAN BUYER
    // subtotal + ongkir + rekber
    // =========================
    totalPembayaran: {
      type: Number,
      required: true,
      min: 0,
    },

    // =========================
    // PEMBAYARAN
    // =========================
    metodePembayaran: {
      type: String,
      enum: ['TRANSFER_REKBER'],
      default: 'TRANSFER_REKBER',
      required: true,
    },

    statusPembayaran: {
      type: String,
      enum: [
        'MENUNGGU_PEMBAYARAN',
        'MENUNGGU_VERIFIKASI',
        'DIVERIFIKASI',
        'DITOLAK',
        'DIKEMBALIKAN',
      ],
      default: 'MENUNGGU_PEMBAYARAN',
      index: true,
    },

    buktiPembayaranUrl: {
      type: String,
      trim: true,
      default: null,
    },

    kodePembayaran: {
      type: String,
      trim: true,
      unique: true,
      sparse: true,
      index: true,
    },

    waktuPembayaran: {
      type: Date,
      default: null,
    },

    waktuVerifikasi: {
      type: Date,
      default: null,
    },

    // =========================
    // STATUS PESANAN
    // =========================
    statusPesanan: {
      type: String,
      enum: [
        'MENUNGGU_PEMBAYARAN',
        'PEMBAYARAN_DIVERIFIKASI',
        'DIPROSES_SELLER',
        'DIKIRIM',
        'DITERIMA',
        'SELESAI',
        'DIBATALKAN',
      ],
      default: 'MENUNGGU_PEMBAYARAN',
      index: true,
    },

    // =========================
    // STATUS DANA REKBER
    // =========================
    statusDana: {
      type: String,
      enum: [
        'BELUM_DIBAYAR',
        'TERKUNCI',
        'TERSEDIA',
        'DICairKAN',
        'SELESAI',
        'DIKEMBALIKAN',
      ],
      default: 'BELUM_DIBAYAR',
      index: true,
    },

    // Jumlah yang nantinya menjadi hak seller.
    // Biaya Rekber tidak masuk ke saldo seller.
    danaSeller: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    // =========================
    // WAKTU PENERIMAAN
    // =========================
    waktuDikirim: {
      type: Date,
      default: null,
    },

    waktuDiterima: {
      type: Date,
      default: null,
    },

    waktuSelesai: {
      type: Date,
      default: null,
    },

    // =========================
    // CATATAN ADMIN
    // =========================
    catatanAdmin: {
      type: String,
      trim: true,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Order', OrderSchema);
