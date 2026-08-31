const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    nama: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 100,
    },

    noHp: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
      minlength: 60,
      select: false,
    },

    role: {
      type: String,
      enum: ['PEMBELI', 'SELLER', 'ADMIN'],
      required: true,
      default: 'PEMBELI',
      index: true,
    },

    isAktif: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', UserSchema);
