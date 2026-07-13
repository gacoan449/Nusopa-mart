const express = require('express');
const router = express.Router();

// Memanggil controller yang sudah dibuat sebelumnya
const adminController = require('../controllers/admin/adminController');
const shippingController = require('../controllers/seller/shippingController');

/**
 * ==========================================
 * RUTING KHUSUS SELLER (PENJUAL)
 * ==========================================
 */

// 1. Endpoint untuk menyelesaikan pesanan saat kurir tiba (COD/Transfer) 
// Sekaligus memicu pemotongan otomatis 1 tiket admin milik seller.
// Method: POST -> http://localhost:5000/api/seller/order/complete
router.post('/seller/order/complete', shippingController.selesaikanPesananDanPotongTiket);

// Note: Anda bisa menambahkan rute pengelolaan produk atau unggah video 
// milik seller di area ini nantinya seiring pengembangan tim Anda.
/**
 * ==========================================
 * RUTING KHUSUS ADMIN (PENGELOLA / ANDA)
 * ==========================================
 */

// 2. Endpoint untuk Admin menambahkan 10 tiket (atau lebih) secara manual 
// setelah menerima bukti transfer atau scan QRIS Rp10.000 dari seller via chat.
// Method: POST -> http://localhost:5000/api/admin/ticket/topup
router.post('/admin/ticket/topup', adminController.tambahTiketSellerManual);


/**
 * ==========================================
 * RUTING KHUSUS USER / PEMBELI (OPSIONAL)
 * ==========================================
 */
// Anda bisa menambahkan rute pelacakan pesanan pembeli di sini 
// untuk mengambil data link cek logistik Chrome yang di-upload oleh seller.


// Mengekspor rute agar dapat dibaca oleh file server utama (server.js)
module.exports = router;
