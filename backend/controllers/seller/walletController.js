const mongoose = require('mongoose');
const Wallet = require('../../models/Wallet');

/*
|--------------------------------------------------------------------------
| MENGAMBIL DATA WALLET SELLER
|--------------------------------------------------------------------------
*/
exports.ambilWallet = async (req, res) => {
  const { sellerId } = req.params;

  if (!sellerId || !mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  try {
    let wallet = await Wallet.findOne({ sellerId });

    if (!wallet) {
      wallet = await Wallet.create({
        sellerId,
        saldoTerkunci: 0,
        saldoTersedia: 0,
        totalDitarik: 0,
        statusWallet: 'AKTIF',
      });
    }

    return res.status(200).json({
      success: true,
      data: wallet,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data wallet.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| UPDATE REKENING BANK SELLER
|--------------------------------------------------------------------------
*/
exports.updateRekening = async (req, res) => {
  const {
    sellerId,
    namaBank,
    nomorRekening,
    namaPemilikRekening,
  } = req.body;

  if (
    !sellerId ||
    !namaBank ||
    !nomorRekening ||
    !namaPemilikRekening
  ) {
    return res.status(400).json({
      success: false,
      message:
        'sellerId, namaBank, nomorRekening, dan namaPemilikRekening wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  try {
    let wallet = await Wallet.findOne({ sellerId });

    if (!wallet) {
      wallet = new Wallet({
        sellerId,
        saldoTerkunci: 0,
        saldoTersedia: 0,
        totalDitarik: 0,
        statusWallet: 'AKTIF',
      });
    }

    if (wallet.statusWallet !== 'AKTIF') {
      return res.status(403).json({
        success: false,
        message: 'Wallet sedang dibekukan.',
      });
    }

    wallet.namaBank = namaBank.trim();
    wallet.nomorRekening = nomorRekening.trim();
    wallet.namaPemilikRekening = namaPemilikRekening.trim();

    await wallet.save();

    return res.status(200).json({
      success: true,
      message: 'Rekening seller berhasil diperbarui.',
      data: {
        namaBank: wallet.namaBank,
        nomorRekening: wallet.nomorRekening,
        namaPemilikRekening: wallet.namaPemilikRekening,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui rekening seller.',
      error: error.message,
    });
  }
};
