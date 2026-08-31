const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const Order = require('../models/Order');
const Payment = require('../models/Payment');
const Wallet = require('../models/Wallet');
const Withdrawal = require('../models/Withdrawal');

const SECRET = 'test-secret-nusopa-mart-2026';
process.env.JWT_SECRET = SECRET;

let buyer;
let seller;
let admin;
let order;
let payment;
let wallet;
let withdrawal;

async function resetDb() {
  await Promise.all([
    User.deleteMany({}),
    Order.deleteMany({}),
    Payment.deleteMany({}),
    Wallet.deleteMany({}),
    Withdrawal.deleteMany({}),
  ]);
}

async function createUsers() {
  const password = await bcrypt.hash('Password123!', 12);

  [buyer, seller, admin] = await User.create([
    { nama: 'Buyer Test', noHp: '081111111111', password, role: 'PEMBELI' },
    { nama: 'Seller Test', noHp: '082222222222', password, role: 'SELLER' },
    { nama: 'Admin Test', noHp: '083333333333', password, role: 'ADMIN' },
  ]);
}

test.before(async () => {
  await resetDb();
  await createUsers();
});

test.after(async () => {
  await resetDb();
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
});

test('1. register model accepts buyer/seller and rejects unsafe admin registration', async () => {
  const sellerTest = await User.create({
    nama: 'Seller Tambahan',
    noHp: '084444444444',
    password: await bcrypt.hash('Password123!', 12),
    role: 'SELLER',
  });

  assert.equal(sellerTest.role, 'SELLER');
  assert.throws(
    () => new User({
      nama: 'Admin Publik',
      noHp: '085555555555',
      password: 'x'.repeat(60),
      role: 'INVALID_ADMIN_PUBLIC',
    }).validateSync(),
    /role/
  );
});

test('2. login password verification and JWT work', async () => {
  const user = await User.findOne({ noHp: buyer.noHp }).select('+password');
  assert.ok(user);
  assert.equal(await bcrypt.compare('Password123!', user.password), true);

  const token = jwt.sign(
    { id: user._id.toString(), role: user.role },
    SECRET,
    { expiresIn: '7d' }
  );

  const decoded = jwt.verify(token, SECRET);
  assert.equal(decoded.id, user._id.toString());
  assert.equal(decoded.role, 'PEMBELI');
});

test('3. buyer creates order with Rekber Rp3.000', async () => {
  const subtotal = 2 * 50000;

  order = await Order.create({
    orderId: 'NSP-TEST-001',
    buyerId: buyer._id,
    sellerId: seller._id,
    namaProduk: 'Produk Test',
    jumlah: 2,
    hargaProduk: 50000,
    subtotal,
    biayaEkspedisi: 15000,
    biayaRekber: 3000,
    totalPembayaran: subtotal + 15000 + 3000,
    metodePembayaran: 'TRANSFER_REKBER',
    statusPembayaran: 'MENUNGGU_PEMBAYARAN',
    statusPesanan: 'MENUNGGU_PEMBAYARAN',
    statusDana: 'BELUM_DIBAYAR',
    danaSeller: subtotal,
    kodePembayaran: 'PAY-TEST-001',
  });

  assert.equal(order.totalPembayaran, 118000);
  assert.equal(order.biayaRekber, 3000);
});

test('4. buyer submits payment proof', async () => {
  payment = await Payment.create({
    orderId: order._id,
    buyerId: buyer._id,
    sellerId: seller._id,
    kodePembayaran: order.kodePembayaran,
    jumlahBarang: order.subtotal,
    biayaEkspedisi: order.biayaEkspedisi,
    biayaRekber: order.biayaRekber,
    totalPembayaran: order.totalPembayaran,
    buktiTransferUrl: 'https://example.test/payment.jpg',
    nominalTransfer: order.totalPembayaran,
    waktuTransfer: new Date(),
    status: 'MENUNGGU_VERIFIKASI',
  });

  order.statusPembayaran = 'MENUNGGU_VERIFIKASI';
  await order.save();

  assert.equal(payment.status, 'MENUNGGU_VERIFIKASI');
});

test('5. admin verifies payment and locks seller funds', async () => {
  wallet = await Wallet.create({
    sellerId: seller._id,
    saldoTerkunci: 0,
    saldoTersedia: 0,
    totalDitarik: 0,
    statusWallet: 'AKTIF',
  });

  wallet.saldoTerkunci += order.subtotal;
  payment.status = 'DIVERIFIKASI';
  payment.diverifikasiOleh = admin._id;
  payment.waktuVerifikasi = new Date();
  order.statusPembayaran = 'DIVERIFIKASI';
  order.statusPesanan = 'PEMBAYARAN_DIVERIFIKASI';
  order.statusDana = 'TERKUNCI';
  await wallet.save();
  await payment.save();
  await order.save();

  assert.equal(order.statusDana, 'TERKUNCI');
  assert.equal(wallet.saldoTerkunci, 100000);
});

test('6. seller can store shipping data', async () => {
  order.namaEkspedisi = 'JNE';
  order.nomorResi = 'JNE123456789';
  order.biayaEkspedisi = 15000;
  order.statusPesanan = 'DIKIRIM';
  order.waktuDikirim = new Date();
  await order.save();

  assert.equal(order.namaEkspedisi, 'JNE');
  assert.equal(order.nomorResi, 'JNE123456789');
  assert.equal(order.statusPesanan, 'DIKIRIM');
});

test('7. buyer confirms receipt and unlocks seller funds', async () => {
  wallet.saldoTerkunci -= order.danaSeller;
  wallet.saldoTersedia += order.danaSeller;
  order.statusPesanan = 'SELESAI';
  order.statusDana = 'TERSEDIA';
  order.waktuDiterima = new Date();
  order.waktuSelesai = new Date();
  await wallet.save();
  await order.save();

  assert.equal(order.statusDana, 'TERSEDIA');
  assert.equal(wallet.saldoTerkunci, 0);
  assert.equal(wallet.saldoTersedia, 100000);
});

test('8. seller wallet balance is available for withdrawal', async () => {
  const currentWallet = await Wallet.findOne({ sellerId: seller._id });
  assert.ok(currentWallet);
  assert.equal(currentWallet.saldoTersedia, 100000);
});

test('9. seller withdrawal moves available balance into pending withdrawal', async () => {
  const currentWallet = await Wallet.findOne({ sellerId: seller._id });

  withdrawal = await Withdrawal.create({
    withdrawalId: 'WD-TEST-001',
    sellerId: seller._id,
    walletId: currentWallet._id,
    jumlah: 100000,
    namaBank: 'BANK TEST',
    nomorRekening: '1234567890',
    namaPemilikRekening: 'Seller Test',
    status: 'MENUNGGU_ADMIN',
  });

  currentWallet.saldoTersedia -= withdrawal.jumlah;
  await currentWallet.save();

  assert.equal(withdrawal.status, 'MENUNGGU_ADMIN');
  assert.equal(currentWallet.saldoTersedia, 0);
});

test('10. admin records manual transfer', async () => {
  withdrawal.status = 'SUDAH_DITRANSFER';
  withdrawal.ditransferOleh = admin._id;
  withdrawal.waktuTransfer = new Date();
  withdrawal.nomorReferensiTransfer = 'TRF-ADMIN-001';
  withdrawal.buktiTransferUrl = 'https://example.test/transfer.jpg';
  await withdrawal.save();

  const currentWallet = await Wallet.findOne({ sellerId: seller._id });
  currentWallet.totalDitarik += withdrawal.jumlah;
  await currentWallet.save();

  assert.equal(withdrawal.status, 'SUDAH_DITRANSFER');
  assert.equal(withdrawal.ditransferOleh.toString(), admin._id.toString());
  assert.equal(withdrawal.nomorReferensiTransfer, 'TRF-ADMIN-001');
  assert.equal(currentWallet.totalDitarik, 100000);
});
