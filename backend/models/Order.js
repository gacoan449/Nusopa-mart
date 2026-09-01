const mongoose = require('mongoose');

const OrderSchema = new mongoose.Schema({
  orderId: { type: String, required: true, unique: true, index: true, trim: true },
  buyerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  productId: { type: String, trim: true, default: null, index: true },
  namaProduk: { type: String, required: true, trim: true, maxlength: 200 },
  jumlah: { type: Number, required: true, min: 1 },
  hargaProduk: { type: Number, required: true, min: 0 },
  subtotal: { type: Number, required: true, min: 0 },
  namaEkspedisi: { type: String, trim: true, default: null },
  nomorResi: { type: String, trim: true, default: null },
  biayaEkspedisi: { type: Number, min: 0, default: 0 },
  biayaRekber: { type: Number, required: true, min: 0, default: 3000 },
  totalPembayaran: { type: Number, required: true, min: 0 },
  metodePembayaran: { type: String, enum: ['TRANSFER_REKBER'], default: 'TRANSFER_REKBER' },
  statusPembayaran: { type: String, enum: ['MENUNGGU_PEMBAYARAN','MENUNGGU_VERIFIKASI','DIVERIFIKASI','DITOLAK','DIKEMBALIKAN'], default: 'MENUNGGU_PEMBAYARAN', index: true },
  buktiPembayaranUrl: { type: String, trim: true, default: null },
  kodePembayaran: { type: String, trim: true, unique: true, sparse: true, index: true },
  waktuPembayaran: { type: Date, default: null },
  waktuVerifikasi: { type: Date, default: null },
  statusPesanan: { type: String, enum: ['MENUNGGU_PEMBAYARAN','PEMBAYARAN_DIVERIFIKASI','DIPROSES_SELLER','DIKIRIM','DITERIMA','SELESAI','DIBATALKAN'], default: 'MENUNGGU_PEMBAYARAN', index: true },
  statusDana: { type: String, enum: ['BELUM_DIBAYAR','TERKUNCI','TERSEDIA','DIKEMBALIKAN'], default: 'BELUM_DIBAYAR', index: true },
  danaSeller: { type: Number, required: true, min: 0, default: 0 },
  waktuDikirim: { type: Date, default: null },
  waktuDiterima: { type: Date, default: null },
  waktuSelesai: { type: Date, default: null },
  autoReleaseAt: { type: Date, default: null, index: true },
  releasedBy: { type: String, enum: ['BUYER','AUTO','ADMIN',null], default: null },
  releaseIdempotencyKey: { type: String, unique: true, sparse: true, index: true },
  catatanAdmin: { type: String, trim: true, default: '', maxlength: 1000 },
}, { timestamps: true });

OrderSchema.index({ sellerId: 1, statusDana: 1, createdAt: -1 });
OrderSchema.index({ buyerId: 1, createdAt: -1 });
OrderSchema.index({ statusDana: 1, autoReleaseAt: 1 });

module.exports = mongoose.model('Order', OrderSchema);
