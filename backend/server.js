const express = require('express');
const mongoose = require('mongoose'); // Library untuk koneksi ke database MongoDB
const apiRoutes = require('./routes/api');

const app = express();

// Middleware wajib agar backend bisa membaca data kiriman format JSON dari Flutter
app.use(express.json());

// 1. KONEKSI KE DATABASE (Silakan ganti URL sesuai database lokal atau cloud Anda)
const MONGO_URI = 'mongodb://localhost:27017/nusopa_mart_db'; 
mongoose.connect(MONGO_URI)
  .then(() => console.log('Database MongoDB Nusopa.Mart Berhasil Terhubung!'))
  .catch((err) => console.error('Gagal terhubung ke database:', err));

// 2. MENGHUBUNGKAN RUTE API
// Semua endpoint sekarang bisa diakses dengan awalan /api (Contoh: /api/seller/order/complete)
app.use('/api', apiRoutes);

// 3. MENJALANKAN SERVER BACKEND
const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server Nusopa.Mart berjalan mewah di port ${PORT}`);
});
