const mongoose = require('mongoose');

const OrderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Seller', required: true },
  namaProduk: { type: String, required: true },
  totalHarga: { type: Number, required: true },
  metodePembayaran: { 
    type: String, 
    enum: ['COD', 'TRANSFER_SAAT_KURIR_TIBA'], 
    required: true 
  },
  statusPesanan: { 
    type: String, 
    enum: ['DIKEMAS', 'DIKIRIM', 'SELESAI'], 
    default: 'DIKEMAS' 
  },
  isTiketDipotong: { type: Boolean, default: false } // Pengaman agar 1 transaksi hanya memotong 1 tiket
}, { timestamps: true });

module.exports = mongoose.model('Order', OrderSchema);
