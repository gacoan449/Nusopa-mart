const mongoose = require('mongoose');
const Withdrawal = require('../../models/Withdrawal');
const Wallet = require('../../models/Wallet');

const generateWithdrawalId = () => `WD-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;

exports.ajukanPenarikan = async (req, res) => {
  const sellerId = req.user.id;
  const { jumlah } = req.body;
  const nominal = Number(jumlah);
  if (!Number.isInteger(nominal) || nominal <= 0) return res.status(400).json({ success:false, message:'Jumlah penarikan tidak valid.' });
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const wallet = await Wallet.findOne({ sellerId }).session(session);
    if (!wallet) throw new Error('Wallet seller belum tersedia.');
    if (wallet.statusWallet !== 'AKTIF') throw new Error('Wallet seller sedang dibekukan.');
    if (nominal > wallet.saldoTersedia) throw new Error('Saldo tersedia tidak mencukupi.');
    if (!wallet.namaBank || !wallet.nomorRekening || !wallet.namaPemilikRekening) throw new Error('Data rekening seller belum lengkap.');
    const aktif = await Withdrawal.findOne({ sellerId, status:{ $in:['MENUNGGU_ADMIN','DIPROSES_ADMIN'] } }).session(session);
    if (aktif) throw new Error('Masih ada penarikan yang sedang diproses.');
    const withdrawal = new Withdrawal({ withdrawalId:generateWithdrawalId(), sellerId:wallet.sellerId, walletId:wallet._id, jumlah:nominal, namaBank:wallet.namaBank, nomorRekening:wallet.nomorRekening, namaPemilikRekening:wallet.namaPemilikRekening, status:'MENUNGGU_ADMIN' });
    wallet.saldoTersedia -= nominal;
    await wallet.save({session}); await withdrawal.save({session}); await session.commitTransaction();
    return res.status(201).json({ success:true, message:'Permintaan penarikan berhasil dibuat.', data:{ withdrawalId:withdrawal.withdrawalId, jumlah:withdrawal.jumlah, status:withdrawal.status, saldoTersedia:wallet.saldoTersedia } });
  } catch (error) { await session.abortTransaction(); return res.status(400).json({ success:false, message:error.message }); }
  finally { await session.endSession(); }
};

exports.ambilAntreanPenarikan = async (req, res) => {
  try { const data = await Withdrawal.find({ status:{ $in:['MENUNGGU_ADMIN','DIPROSES_ADMIN'] } }).populate('sellerId','nama noHp').sort({createdAt:1}); return res.json({ success:true, total:data.length, data }); }
  catch (error) { return res.status(500).json({ success:false, message:'Gagal mengambil antrean penarikan.', error:error.message }); }
};

exports.mulaiProsesPenarikan = async (req, res) => {
  const { withdrawalId } = req.body;
  if (!withdrawalId) return res.status(400).json({success:false,message:'withdrawalId wajib diisi.'});
  try { const w = await Withdrawal.findOne({withdrawalId}); if (!w) return res.status(404).json({success:false,message:'Data penarikan tidak ditemukan.'}); if (w.status !== 'MENUNGGU_ADMIN') return res.status(400).json({success:false,message:`Status saat ini ${w.status}.`}); w.status='DIPROSES_ADMIN'; await w.save(); return res.json({success:true,message:'Penarikan sedang diproses Admin.',data:{withdrawalId:w.withdrawalId,status:w.status}}); }
  catch(error){return res.status(500).json({success:false,message:'Gagal memproses penarikan.',error:error.message});}
};

exports.konfirmasiTransfer = async (req, res) => {
  const { withdrawalId, nomorReferensiTransfer, buktiTransferUrl, catatanAdmin } = req.body;
  const adminId = req.user.id;
  if (!withdrawalId || !nomorReferensiTransfer) return res.status(400).json({success:false,message:'withdrawalId dan nomorReferensiTransfer wajib diisi.'});
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const w = await Withdrawal.findOne({withdrawalId}).session(session); if (!w) throw new Error('Data penarikan tidak ditemukan.');
    if (!['MENUNGGU_ADMIN','DIPROSES_ADMIN'].includes(w.status)) throw new Error(`Penarikan sudah diproses dengan status ${w.status}.`);
    const wallet = await Wallet.findById(w.walletId).session(session); if (!wallet) throw new Error('Wallet seller tidak ditemukan.');
    wallet.totalDitarik += w.jumlah;
    w.status='SUDAH_DITRANSFER'; w.ditransferOleh=adminId; w.waktuTransfer=new Date(); w.nomorReferensiTransfer=String(nomorReferensiTransfer).trim(); w.buktiTransferUrl=buktiTransferUrl || null; w.catatanAdmin=catatanAdmin || '';
    await wallet.save({session}); await w.save({session}); await session.commitTransaction();
    return res.json({success:true,message:'Penarikan ditandai sudah ditransfer.',data:{withdrawalId:w.withdrawalId,jumlah:w.jumlah,status:w.status,nomorReferensiTransfer:w.nomorReferensiTransfer,waktuTransfer:w.waktuTransfer}});
  } catch(error){await session.abortTransaction();return res.status(400).json({success:false,message:error.message});} finally{await session.endSession();}
};

exports.tolakPenarikan = async (req, res) => {
  const { withdrawalId, catatanAdmin } = req.body;
  const adminId = req.user.id;
  if (!withdrawalId) return res.status(400).json({success:false,message:'withdrawalId wajib diisi.'});
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const w = await Withdrawal.findOne({withdrawalId}).session(session); if (!w) throw new Error('Data penarikan tidak ditemukan.');
    if (!['MENUNGGU_ADMIN','DIPROSES_ADMIN'].includes(w.status)) throw new Error(`Status saat ini ${w.status}.`);
    const wallet = await Wallet.findById(w.walletId).session(session); if (!wallet) throw new Error('Wallet seller tidak ditemukan.');
    wallet.saldoTersedia += w.jumlah;
    w.status='DITOLAK'; w.ditransferOleh=adminId; w.catatanAdmin=catatanAdmin || 'Penarikan ditolak oleh Admin.';
    await wallet.save({session}); await w.save({session}); await session.commitTransaction();
    return res.json({success:true,message:'Penarikan ditolak dan saldo dikembalikan.',data:{withdrawalId:w.withdrawalId,status:w.status,saldoTersedia:wallet.saldoTersedia}});
  } catch(error){await session.abortTransaction();return res.status(400).json({success:false,message:error.message});} finally{await session.endSession();}
};

exports.riwayatPenarikanSeller = async (req, res) => {
  try { const data = await Withdrawal.find({sellerId:req.user.id}).sort({createdAt:-1}); return res.json({success:true,total:data.length,data}); }
  catch(error){return res.status(500).json({success:false,message:'Gagal mengambil riwayat penarikan.',error:error.message});}
};
