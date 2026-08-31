const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.warn(
    'WARNING: JWT_SECRET belum diset. Gunakan file .env pada production.'
  );
}

/*
|--------------------------------------------------------------------------
| AUTHENTICATION MIDDLEWARE
|--------------------------------------------------------------------------
| Membaca:
| Authorization: Bearer <token>
|--------------------------------------------------------------------------
*/
function auth(req, res, next) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization) {
      return res.status(401).json({
        success: false,
        message: 'Token autentikasi wajib diberikan.',
      });
    }

    const parts = authorization.split(' ');

    if (
      parts.length !== 2 ||
      parts[0] !== 'Bearer' ||
      !parts[1]
    ) {
      return res.status(401).json({
        success: false,
        message: 'Format token tidak valid.',
      });
    }

    if (!JWT_SECRET) {
      return res.status(500).json({
        success: false,
        message: 'Konfigurasi JWT_SECRET belum tersedia di server.',
      });
    }

    const token = parts[1];

    const decoded = jwt.verify(
      token,
      JWT_SECRET
    );

    /*
     * Data user hasil verifikasi token
     * tersedia melalui req.user
     */
    req.user = {
      id: decoded.id || decoded.userId,
      role: decoded.role,
      email: decoded.email || null,
    };

    if (!req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak memiliki identitas user yang valid.',
      });
    }

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token sudah kedaluwarsa. Silakan login kembali.',
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token tidak valid.',
      });
    }

    return res.status(401).json({
      success: false,
      message: 'Autentikasi gagal.',
    });
  }
}

module.exports = auth;
