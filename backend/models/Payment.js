const mongoose = require('mongoose');

const PaymentSchema = new mongoose.Schema(
  {
    // =========================
    // RELASI TRANSAKSI
    // =========================
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: true,
      unique: true,
      index: true,
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
    // KODE & NOMINAL
    // =========================
    kodePembayaran: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    jumlahBarang: {
      type: Number,
      required: true,
      min: 0,
    },

    biayaEkspedisi: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    biayaRekber: {
      type: Number,
      required: true,
      min: 0,
      default: 3000,
    },

    totalPembayaran: {
      type: Number,
      required: true,
      min: 0,
    },

    // =========================
    // BUKTI TRANSFER BUYER
    // =========================
    buktiTransferUrl: {
      type: String,
      trim: true,
      default: null,
    },

    nominalTransfer: {
      type: Number,
      min: 0,
      default: 0,
    },

    waktuTransfer: {
      type: Date,
      default: null,
    },

    // =========================
    // VERIFIKASI ADMIN
    // =========================
    status: {
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

    diverifikasiOleh: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    waktuVerifikasi: {
      type: Date,
      default: null,
    },

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

module.exports = mongoose.model('Payment', PaymentSchema);
