const mongoose = require('mongoose');

const WithdrawalSchema = new mongoose.Schema(
  {
    // =========================
    // IDENTITAS PENARIKAN
    // =========================
    withdrawalId: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    walletId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Wallet',
      required: true,
      index: true,
    },

    // =========================
    // NOMINAL
    // =========================
    jumlah: {
      type: Number,
      required: true,
      min: 1,
    },

    // =========================
    // REKENING TUJUAN
    // Disimpan sebagai snapshot transaksi
    // agar perubahan rekening seller
    // tidak mengubah histori WD lama.
    // =========================
    namaBank: {
      type: String,
      required: true,
      trim: true,
    },

    nomorRekening: {
      type: String,
      required: true,
      trim: true,
    },

    namaPemilikRekening: {
      type: String,
      required: true,
      trim: true,
    },

    // =========================
    // STATUS PENARIKAN
    // =========================
    status: {
      type: String,
      enum: [
        'MENUNGGU_ADMIN',
        'DIPROSES_ADMIN',
        'SUDAH_DITRANSFER',
        'DITOLAK',
        'DIBATALKAN',
      ],
      default: 'MENUNGGU_ADMIN',
      index: true,
    },

    // =========================
    // INFORMASI TRANSFER ADMIN
    // =========================
    ditransferOleh: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    waktuTransfer: {
      type: Date,
      default: null,
    },

    nomorReferensiTransfer: {
      type: String,
      trim: true,
      default: null,
    },

    buktiTransferUrl: {
      type: String,
      trim: true,
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

module.exports = mongoose.model('Withdrawal', WithdrawalSchema);
