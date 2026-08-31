const mongoose = require('mongoose');

const WalletSchema = new mongoose.Schema(
  {
    // =========================
    // PEMILIK WALLET
    // =========================
    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    // =========================
    // SALDO
    // =========================
    saldoTerkunci: {
      type: Number,
      default: 0,
      min: 0,
    },

    saldoTersedia: {
      type: Number,
      default: 0,
      min: 0,
    },

    totalDitarik: {
      type: Number,
      default: 0,
      min: 0,
    },

    // =========================
    // INFORMASI REKENING SELLER
    // =========================
    namaBank: {
      type: String,
      trim: true,
      default: '',
    },

    nomorRekening: {
      type: String,
      trim: true,
      default: '',
    },

    namaPemilikRekening: {
      type: String,
      trim: true,
      default: '',
    },

    // =========================
    // STATUS WALLET
    // =========================
    statusWallet: {
      type: String,
      enum: ['AKTIF', 'DIBEKUKAN'],
      default: 'AKTIF',
      index: true,
    },

    // =========================
    // CATATAN
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

module.exports = mongoose.model('Wallet', WalletSchema);
