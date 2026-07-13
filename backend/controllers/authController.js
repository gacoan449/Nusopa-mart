const User = require('../models/User');

// 1. FUNGSI DAFTAR AKUN BARU
exports.register = async (req, res) => {
  const { nama, noHp, password, role } = req.body;
  try {
    const userSama = await User.findOne({ noHp });
    if (userSama) return res.status(400).json({ success: false, message: 'Nomor HP sudah terdaftar!' });

    const userBaru = new User({ nama, noHp, password, role });
    await userBaru.save();
    return res.status(201).json({ success: true, message: 'Pendaftaran berhasil!' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. FUNGSI LOGIN / MASUK AKUN
exports.login = async (req, res) => {
  const { noHp, password } = req.body;
  try {
    const user = await User.findOne({ noHp });
    if (!user || user.password !== password) {
      return res.status(400).json({ success: false, message: 'Nomor HP atau Password salah!' });
    }
    // Mengembalikan data user beserta rolenya ke Flutter
    return res.status(200).json({
      success: true,
      message: 'Login berhasil!',
      user: { id: user._id, nama: user.nama, role: user.role }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
