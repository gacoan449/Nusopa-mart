const Wallet = require('../../models/Wallet');

exports.ambilWallet = async (req, res) => {
  const sellerId = req.user.id;
  try {
    let wallet = await Wallet.findOne({ sellerId });
    if (!wallet) wallet = await Wallet.create({ sellerId, saldoTerkunci:0, saldoTersedia:0, totalDitarik:0, statusWallet:'AKTIF' });
    if (wallet.statusWallet !== 'AKTIF') return res.status(403).json({ success:false, message:'Wallet sedang dibekukan.' });
    return res.json({ success:true, data:wallet });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal mengambil data wallet.', error:error.message }); }
};

exports.updateRekening = async (req, res) => {
  const { namaBank, nomorRekening, namaPemilikRekening } = req.body;
  if (!namaBank || !nomorRekening || !namaPemilikRekening) return res.status(400).json({ success:false, message:'namaBank, nomorRekening, dan namaPemilikRekening wajib diisi.' });
  try {
    let wallet = await Wallet.findOne({ sellerId:req.user.id });
    if (!wallet) wallet = new Wallet({ sellerId:req.user.id, saldoTerkunci:0, saldoTersedia:0, totalDitarik:0, statusWallet:'AKTIF' });
    if (wallet.statusWallet !== 'AKTIF') return res.status(403).json({ success:false, message:'Wallet sedang dibekukan.' });
    wallet.namaBank = String(namaBank).trim();
    wallet.nomorRekening = String(nomorRekening).trim();
    wallet.namaPemilikRekening = String(namaPemilikRekening).trim();
    await wallet.save();
    return res.json({ success:true, message:'Rekening seller berhasil diperbarui.', data:{ namaBank:wallet.namaBank, nomorRekening:wallet.nomorRekening, namaPemilikRekening:wallet.namaPemilikRekening } });
  } catch (error) { return res.status(500).json({ success:false, message:'Gagal memperbarui rekening seller.', error:error.message }); }
};
