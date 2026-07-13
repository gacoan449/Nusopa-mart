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
