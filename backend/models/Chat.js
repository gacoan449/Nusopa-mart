const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema({
  pengirimId: { type: mongoose.Schema.Types.ObjectId, required: true }, // Bisa ID Admin atau ID Seller
  penerimaId: { type: mongoose.Schema.Types.ObjectId, required: true },
  pesanTeks: { type: String, default: "" },
  fileGambarUrl: { type: String, default: null }, // Tempat menaruh link foto QRIS dari Admin
  waktuKirim: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Chat', ChatSchema);
