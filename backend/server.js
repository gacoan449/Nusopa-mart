const express = require('express');
const mongoose = require('mongoose');
const apiRoutes = require('./routes/api');

const app = express();

const PORT = process.env.PORT || 5000;
const MONGO_URI =
  process.env.MONGO_URI ||
  'mongodb://localhost:27017/nusopa_mart_db';

// ============================================================
// MIDDLEWARE
// ============================================================

app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// ============================================================
// HEALTH CHECK
// ============================================================

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Nusopa.Mart Backend aktif.',
    service: 'Nusopa.Mart API',
    timestamp: new Date(),
  });
});

// ============================================================
// API ROUTES
// ============================================================

app.use('/api', apiRoutes);

// ============================================================
// 404 HANDLER
// ============================================================

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint tidak ditemukan.',
    path: req.originalUrl,
  });
});

// ============================================================
// GLOBAL ERROR HANDLER
// ============================================================

app.use((err, req, res, next) => {
  console.error('API ERROR:', err);

  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Terjadi kesalahan pada server.',
  });
});

// ============================================================
// DATABASE + SERVER
// ============================================================

async function startServer() {
  try {
    await mongoose.connect(MONGO_URI);

    console.log('MongoDB Nusopa.Mart berhasil terhubung.');

    app.listen(PORT, () => {
      console.log(
        `Nusopa.Mart Backend berjalan di port ${PORT}`
      );
    });
  } catch (error) {
    console.error(
      'Gagal terhubung ke MongoDB:',
      error.message
    );

    process.exit(1);
  }
}

// ============================================================
// GRACEFUL SHUTDOWN
// ============================================================

async function shutdown(signal) {
  console.log(`${signal} diterima. Menutup server...`);

  try {
    await mongoose.connection.close();

    console.log('Koneksi MongoDB ditutup.');
    process.exit(0);
  } catch (error) {
    console.error(
      'Gagal menutup koneksi MongoDB:',
      error.message
    );

    process.exit(1);
  }
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

startServer();
