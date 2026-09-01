const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { adminOnly, sellerOnly, buyerOnly } = require('../middleware/role');
const authController = require('../controllers/authController');
const orderController = require('../controllers/orderController');
const paymentController = require('../controllers/admin/paymentController');
const shippingController = require('../controllers/seller/shippingController');
const walletController = require('../controllers/seller/walletController');
const withdrawalController = require('../controllers/admin/withdrawalController');

router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);

router.post('/orders', auth, buyerOnly, orderController.buatPesanan);
router.get('/orders/buyer', auth, buyerOnly, orderController.ambilPesananBuyer);
router.get('/orders/seller', auth, sellerOnly, orderController.ambilPesananSeller);
router.get('/orders/:orderId', auth, orderController.ambilDetailPesanan);
router.post('/orders/received', auth, buyerOnly, orderController.konfirmasiBarangDiterima);
router.post('/orders/:orderId/review', auth, buyerOnly, orderController.buatUlasan);

router.post('/payments/proof', auth, buyerOnly, paymentController.kirimBuktiPembayaran);
router.post('/admin/payments/verify', auth, adminOnly, paymentController.verifikasiPembayaran);
router.post('/admin/payments/reject', auth, adminOnly, paymentController.tolakPembayaran);
router.post('/admin/escrow/auto-release', auth, adminOnly, orderController.autoRelease);

router.post('/shipping', auth, sellerOnly, shippingController.kirimPesanan);
router.get('/wallet', auth, sellerOnly, walletController.ambilWallet);
router.put('/wallet/account', auth, sellerOnly, walletController.updateRekening);
router.post('/withdrawals', auth, sellerOnly, withdrawalController.ajukanPenarikan);
router.get('/withdrawals/seller', auth, sellerOnly, withdrawalController.riwayatPenarikanSeller);
router.get('/admin/withdrawals', auth, adminOnly, withdrawalController.ambilAntreanPenarikan);
router.post('/admin/withdrawals/process', auth, adminOnly, withdrawalController.mulaiProsesPenarikan);
router.post('/admin/withdrawals/transfer', auth, adminOnly, withdrawalController.konfirmasiTransfer);
router.post('/admin/withdrawals/reject', auth, adminOnly, withdrawalController.tolakPenarikan);

router.get('/health', (req, res) => res.status(200).json({ success:true, message:'Nusopa.Mart API aktif.', timestamp:new Date() }));
module.exports = router;
