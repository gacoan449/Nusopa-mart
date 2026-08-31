const express = require('express');

const router = express.Router();

// ============================================================
// MIDDLEWARE
// ============================================================

const auth = require('../middleware/auth');
const {
  adminOnly,
  sellerOnly,
  buyerOnly,
} = require('../middleware/role');

// ============================================================
// CONTROLLERS
// ============================================================

const authController = require('../controllers/authController');
const orderController = require('../controllers/orderController');
const paymentController = require('../controllers/admin/paymentController');
const shippingController = require('../controllers/seller/shippingController');
const walletController = require('../controllers/seller/walletController');
const withdrawalController = require('../controllers/admin/withdrawalController');

// ============================================================
// AUTH
// ============================================================

router.post('/auth/login', authController.login);

// ============================================================
// ORDER - BUYER
// ============================================================

router.post(
  '/orders',
  auth,
  buyerOnly,
  orderController.buatPesanan
);

router.get(
  '/orders/buyer/:buyerId',
  auth,
  buyerOnly,
  orderController.ambilPesananBuyer
);

router.get(
  '/orders/:orderId',
  auth,
  orderController.ambilDetailPesanan
);

router.post(
  '/orders/received',
  auth,
  buyerOnly,
  orderController.konfirmasiBarangDiterima
);

// ============================================================
// ORDER - SELLER
// ============================================================

router.get(
  '/orders/seller/:sellerId',
  auth,
  sellerOnly,
  orderController.ambilPesananSeller
);

// ============================================================
// PAYMENT / REKBER
// ============================================================

router.post(
  '/payments/proof',
  auth,
  buyerOnly,
  paymentController.kirimBuktiPembayaran
);

router.post(
  '/admin/payments/verify',
  auth,
  adminOnly,
  paymentController.verifikasiPembayaran
);

router.post(
  '/admin/payments/reject',
  auth,
  adminOnly,
  paymentController.tolakPembayaran
);

// ============================================================
// SHIPPING
// ============================================================

router.post(
  '/shipping',
  auth,
  sellerOnly,
  shippingController.kirimPesanan
);

// ============================================================
// WALLET SELLER
// ============================================================

router.get(
  '/wallet/:sellerId',
  auth,
  sellerOnly,
  walletController.ambilWallet
);

router.put(
  '/wallet/account',
  auth,
  sellerOnly,
  walletController.updateRekening
);

// ============================================================
// WITHDRAWAL SELLER
// ============================================================

router.post(
  '/withdrawals',
  auth,
  sellerOnly,
  withdrawalController.ajukanPenarikan
);

router.get(
  '/withdrawals/seller/:sellerId',
  auth,
  sellerOnly,
  withdrawalController.riwayatPenarikanSeller
);

// ============================================================
// WITHDRAWAL ADMIN
// ============================================================

router.get(
  '/admin/withdrawals',
  auth,
  adminOnly,
  withdrawalController.ambilAntreanPenarikan
);

router.post(
  '/admin/withdrawals/process',
  auth,
  adminOnly,
  withdrawalController.mulaiProsesPenarikan
);

router.post(
  '/admin/withdrawals/transfer',
  auth,
  adminOnly,
  withdrawalController.konfirmasiTransfer
);

router.post(
  '/admin/withdrawals/reject',
  auth,
  adminOnly,
  withdrawalController.tolakPenarikan
);

// ============================================================
// HEALTH CHECK
// ============================================================

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Nusopa.Mart API aktif.',
    timestamp: new Date(),
  });
});

module.exports = router;
