const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

function createToken(user) {
  if (!JWT_SECRET) {
    throw new Error('JWT_SECRET belum dikonfigurasi di server.');
  }

  return jwt.sign(
    {
      id: user._id.toString(),
      role: user.role,
      nama: user.nama,
      noHp: user.noHp,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

// ============================================================
// REGISTER
// ============================================================
exports.register = async (req, res) => {
  const { nama, noHp, password, role } = req.body;

  if (!nama || !noHp || !password || !role) {
    return res.status(400).json({
      success: false,
      message: 'nama, noHp, password, dan role wajib diisi.',
    });
  }

  const normalizedRole = String(role).toUpperCase();

  if (!['PEMBELI', 'SELLER'].includes(normalizedRole)) {
    return res.status(400).json({
      success: false,
      message: 'Role hanya PEMBELI atau SELLER.',
    });
  }

  if (String(password).length < 6) {
    return res.status(400).json({
      success: false,
      message: 'Password minimal 6 karakter.',
    });
  }

  try {
    const userSama = await User.findOne({ noHp: String(noHp).trim() });

    if (userSama) {
      return res.status(409).json({
        success: false,
        message: 'Nomor HP sudah terdaftar.',
      });
    }

    const passwordHash = await bcrypt.hash(
      String(password),
      12
    );

    const userBaru = new User({
      nama: String(nama).trim(),
      noHp: String(noHp).trim(),
      password: passwordHash,
      role: normalizedRole,
    });

    await userBaru.save();

    return res.status(201).json({
      success: true,
      message: 'Pendaftaran berhasil.',
      user: {
        id: userBaru._id,
        nama: userBaru.nama,
        noHp: userBaru.noHp,
        role: userBaru.role,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal melakukan pendaftaran.',
      error: error.message,
    });
  }
};

// ============================================================
// LOGIN
// ============================================================
exports.login = async (req, res) => {
  const { noHp, password } = req.body;

  if (!noHp || !password) {
    return res.status(400).json({
      success: false,
      message: 'Nomor HP dan password wajib diisi.',
    });
  }

  try {
    const user = await User.findOne({
      noHp: String(noHp).trim(),
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Nomor HP atau password salah.',
      });
    }

    const passwordBenar = await bcrypt.compare(
      String(password),
      user.password
    );

    if (!passwordBenar) {
      return res.status(401).json({
        success: false,
        message: 'Nomor HP atau password salah.',
      });
    }

    const token = createToken(user);

    return res.status(200).json({
      success: true,
      message: 'Login berhasil.',
      token,
      expiresIn: JWT_EXPIRES_IN,
      user: {
        id: user._id,
        nama: user.nama,
        noHp: user.noHp,
        role: user.role,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal melakukan login.',
      error: error.message,
    });
  }
};
