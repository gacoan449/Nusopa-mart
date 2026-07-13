const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  nama: { type: String, required: true },
  noHp: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['PEMBELI', 'SELLER'], required: true } // Membedakan hak akses akun
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
