const express = require('express');

const router = express.Router();

// ============================================================
// CONTROLLERS
// ============================================================

// Order
const orderController = require('../controllers/orderController');

// Payment
const paymentController = require('../controllers/admin/paymentController');

// Shipping
const shippingController = require('../controllers/seller/shippingController');

// Wallet
const walletController = require('../controllers/seller/walletController');

// Withdrawal
const withdrawalController = require('../controllers/admin/withdrawalController');


// ============================================================
// ORDER
// ============================================================

// Membuat pesanan baru
router.post(
  '/orders',
  orderController.buatPesanan
);

// Buyer melihat pesanan miliknya
router.get(
  '/orders/buyer/:buyerId',
  orderController.ambilPesananBuyer
);

// Seller melihat pesanan masuk
router.get(
  '/orders/seller/:sellerId',
  orderController.ambilPesananSeller
);

// Detail pesanan
router.get(
  '/orders/:orderId',
  orderController.ambilDetailPesanan
);

// Buyer konfirmasi barang sudah diterima
router.post(
  '/orders/received',
  orderController.konfirmasiBarangDiterima
);


// ============================================================
// PAYMENT / REKBER
// ============================================================

// Buyer mengirim bukti transfer
router.post(
  '/payments/proof',
  paymentController.kirimBuktiPembayaran
);

// Admin memverifikasi pembayaran
router.post(
  '/admin/payments/verify',
  paymentController.verifikasiPembayaran
);

// Admin menolak pembayaran
router.post(
  '/admin/payments/reject',
  paymentController.tolakPembayaran
);


// ============================================================
// SHIPPING
// ============================================================

// Seller mengirim pesanan
// Wajib:
// - nama ekspedisi
// - nomor resi
// - biaya ekspedisi
router.post(
  '/shipping',
  shippingController.kirimPesanan
);


// ============================================================
// WALLET SELLER
// ============================================================

// Seller melihat wallet
router.get(
  '/wallet/:sellerId',
  walletController.ambilWallet
);

// Seller memperbarui rekening
router.put(
  '/wallet/account',
  walletController.updateRekening
);


// ============================================================
// WITHDRAWAL / PENARIKAN DANA
// ============================================================

// Seller mengajukan penarikan
router.post(
  '/withdrawals',
  withdrawalController.ajukanPenarikan
);

// Seller melihat riwayat penarikan
router.get(
  '/withdrawals/seller/:sellerId',
  withdrawalController.riwayatPenarikanSeller
);


// ============================================================
// ADMIN WITHDRAWAL
// ============================================================

// Admin melihat antrean penarikan
router.get(
  '/admin/withdrawals',
  withdrawalController.ambilAntreanPenarikan
);

// Admin mulai memproses penarikan
router.post(
  '/admin/withdrawals/process',
  withdrawalController.mulaiProsesPenarikan
);

// Admin mengonfirmasi transfer manual sudah dilakukan
router.post(
  '/admin/withdrawals/transfer',
  withdrawalController.konfirmasiTransfer
);

// Admin menolak penarikan
router.post(
  '/admin/withdrawals/reject',
  withdrawalController.tolakPenarikan
);


// ============================================================
// HEALTH CHECK
// ============================================================

router.get(
  '/health',
  (req, res) => {
    res.status(200).json({
      success: true,
      message: 'Nusopa.Mart API aktif.',
      timestamp: new Date(),
    });
  }
);


module.exports = router;
