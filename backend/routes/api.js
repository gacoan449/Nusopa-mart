const express = require('express');
const router = express.Router();

// Memanggil semua controller yang sudah dibuat sebelumnya
const authController = require('../controllers/authController');
const adminController = require('../controllers/admin/adminController');
const shippingController = require('../controllers/seller/shippingController');
const chatController = require('../controllers/admin/chatController');

/**
 * ==========================================
 * 0. RUTING AUTENTIKASI (LOGIN & REGISTER)
 * ==========================================
 */

// Endpoint untuk mendaftarkan akun baru pembeli / seller
// Method: POST -> http://localhost:5000/api/auth/register
router.post('/auth/register', authController.register);

// Endpoint untuk login akun nyata yang divalidasi ke database
// Method: POST -> http://localhost:5000/api/auth/login
router.post('/auth/login', authController.login);


/**
 * ==========================================
 * 1. RUTING KHUSUS SELLER (PENJUAL)
 * ==========================================
 */

// Endpoint untuk menyelesaikan pesanan saat kurir tiba (COD/Transfer)
// Sekaligus memicu pemotongan otomatis 1 tiket admin milik seller.
// Method: POST -> http://localhost:5000/api/seller/order/complete
router.post('/seller/order/complete', shippingController.selesaikanPesananDanPotongTiket);


/**
 * ==========================================
 * 2. RUTING KHUSUS ADMIN (PENGELOLA / ANDA)
 * ==========================================
 */

// Endpoint untuk Admin menambahkan tiket secara manual setelah menerima 
// bukti transfer atau scan QRIS Rp10.000 (10 tiket) dari seller via chat.
// Method: POST -> http://localhost:5000/api/admin/ticket/topup
router.post('/admin/ticket/topup', adminController.tambahTiketSellerManual);


/**
 * ==========================================
 * 3. RUTING KHUSUS FITUR CHAT ADMIN & SELLER
 * ==========================================
 */

// Endpoint untuk mengirim pesan chat (bisa teks biasa atau link gambar QRIS manual)
// Method: POST -> http://localhost:5000/api/chat/send
router.post('/chat/send', chatController.kirimPesanChat);

// Endpoint untuk mengambil riwayat percakapan dua arah antara Admin dan Seller
// Method: GET -> http://localhost:5000/api/chat/history/:pengirimId/:penerimaId
router.get('/chat/history/:pengirimId/:penerimaId', chatController.ambilRiwayatChat);


// Mengekspor rute agar dapat dibaca oleh file server utama (server.js)
module.exports = router;
