const mongoose = require('mongoose');

const TicketSchema = new mongoose.Schema({
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Seller',
    required: true
  },
  sisaTiket: {
    type: Number,
    default: 0, // Default awal mendaftar adalah 0 tiket
    required: true
  },
  riwayatPembelian: [{
    jumlahTiket: Number,
    tanggalBeli: { type: Date, default: Date.now },
    statusVerifikasi: { type: String, enum: ['PENDING', 'SUKSES'], default: 'SUKSES' } // Diinput manual oleh Admin via chat QRIS
  }]
}, { timestamps: true });

module.exports = mongoose.model('Ticket', TicketSchema);
