const mongoose = require('mongoose');
const Withdrawal = require('../../models/Withdrawal');
const Wallet = require('../../models/Wallet');

/*
|--------------------------------------------------------------------------
| GENERATE ID PENARIKAN
|--------------------------------------------------------------------------
*/
function generateWithdrawalId() {
  const waktu = Date.now().toString().slice(-8);
  const acak = Math.floor(100 + Math.random() * 900);

  return `WD-${waktu}-${acak}`;
}

/*
|--------------------------------------------------------------------------
| SELLER MENGAJUKAN PENARIKAN
|--------------------------------------------------------------------------
| Saldo langsung dipindahkan:
|
| saldoTersedia
|       ↓
| ditahan untuk Withdrawal
|
| Kita menggunakan saldoTersedia sebagai saldo yang benar-benar
| masih dapat ditarik.
|--------------------------------------------------------------------------
*/
exports.ajukanPenarikan = async (req, res) => {
  const {
    sellerId,
    jumlah,
  } = req.body;

  if (!sellerId || jumlah === undefined || jumlah === null) {
    return res.status(400).json({
      success: false,
      message: 'sellerId dan jumlah wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  const nominal = Number(jumlah);

  if (!Number.isFinite(nominal) || nominal <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Jumlah penarikan tidak valid.',
    });
  }

  if (!Number.isInteger(nominal)) {
    return res.status(400).json({
      success: false,
      message: 'Jumlah penarikan harus berupa angka bulat.',
    });
  }

  const session = await mongoose.startSession();

  try {
    session.startTransaction();

    const wallet = await Wallet.findOne({
      sellerId,
    }).session(session);

    if (!wallet) {
      throw new Error('Wallet seller belum tersedia.');
    }

    if (wallet.statusWallet !== 'AKTIF') {
      throw new Error('Wallet seller sedang dibekukan.');
    }

    if (nominal > wallet.saldoTersedia) {
      throw new Error('Saldo tersedia tidak mencukupi.');
    }

    if (
      !wallet.namaBank ||
      !wallet.nomorRekening ||
      !wallet.namaPemilikRekening
    ) {
      throw new Error(
        'Data rekening seller belum lengkap. Lengkapi rekening terlebih dahulu.'
      );
    }

    /*
     * Mencegah seller memiliki beberapa WD aktif
     * yang dapat menyulitkan rekonsiliasi manual Admin.
     */
    const withdrawalAktif = await Withdrawal.findOne({
      sellerId,
      status: {
        $in: [
          'MENUNGGU_ADMIN',
          'DIPROSES_ADMIN',
        ],
      },
    }).session(session);

    if (withdrawalAktif) {
      throw new Error(
        'Masih ada penarikan yang sedang diproses. Tunggu sampai selesai.'
      );
    }

    const withdrawal = new Withdrawal({
      withdrawalId: generateWithdrawalId(),
      sellerId: wallet.sellerId,
      walletId: wallet._id,
      jumlah: nominal,

      // Snapshot rekening saat pengajuan
      namaBank: wallet.namaBank,
      nomorRekening: wallet.nomorRekening,
      namaPemilikRekening: wallet.namaPemilikRekening,

      status: 'MENUNGGU_ADMIN',
    });

    /*
     * Dana ditahan dari saldo tersedia.
     * Belum dianggap sudah dibayar sampai Admin
     * benar-benar melakukan transfer.
     */
    wallet.saldoTersedia -= nominal;

    await wallet.save({ session });
    await withdrawal.save({ session });

    await session.commitTransaction();

    return res.status(201).json({
      success: true,
      message:
        'Permintaan penarikan berhasil dibuat dan menunggu transfer Admin.',
      data: {
        withdrawalId: withdrawal.withdrawalId,
        jumlah: withdrawal.jumlah,
        status: withdrawal.status,
        saldoTersedia: wallet.saldoTersedia,
      },
    });
  } catch (error) {
    await session.abortTransaction();

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  } finally {
    await session.endSession();
  }
};

/*
|--------------------------------------------------------------------------
| ADMIN MELIHAT ANTREAN PENARIKAN
|--------------------------------------------------------------------------
*/
exports.ambilAntreanPenarikan = async (req, res) => {
  try {
    const withdrawals = await Withdrawal.find({
      status: {
        $in: [
          'MENUNGGU_ADMIN',
          'DIPROSES_ADMIN',
        ],
      },
    })
      .populate('sellerId', 'nama email')
      .sort({ createdAt: 1 });

    return res.status(200).json({
      success: true,
      total: withdrawals.length,
      data: withdrawals,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil antrean penarikan.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| ADMIN MULAI MEMPROSES PENARIKAN
|--------------------------------------------------------------------------
*/
exports.mulaiProsesPenarikan = async (req, res) => {
  const {
    withdrawalId,
  } = req.body;

  if (!withdrawalId) {
    return res.status(400).json({
      success: false,
      message: 'withdrawalId wajib diisi.',
    });
  }

  try {
    const withdrawal = await Withdrawal.findOne({
      withdrawalId,
    });

    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Data penarikan tidak ditemukan.',
      });
    }

    if (withdrawal.status !== 'MENUNGGU_ADMIN') {
      return res.status(400).json({
        success: false,
        message:
          `Penarikan tidak dapat diproses. Status saat ini: ${withdrawal.status}.`,
      });
    }

    withdrawal.status = 'DIPROSES_ADMIN';

    await withdrawal.save();

    return res.status(200).json({
      success: true,
      message: 'Penarikan ditandai sedang diproses Admin.',
      data: {
        withdrawalId: withdrawal.withdrawalId,
        status: withdrawal.status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses penarikan.',
      error: error.message,
    });
  }
};

/*
|--------------------------------------------------------------------------
| ADMIN KONFIRMASI SUDAH TRANSFER
|--------------------------------------------------------------------------
| PENTING:
| Fungsi ini hanya boleh dipanggil SETELAH Admin benar-benar
| melakukan transfer bank secara manual.
|--------------------------------------------------------------------------
*/
exports.konfirmasiTransfer = async (req, res) => {
  const {
    withdrawalId,
    adminId,
    nomorReferensiTransfer,
    buktiTransferUrl,
    catatanAdmin,
  } = req.body;

  if (
    !withdrawalId ||
    !adminId ||
    !nomorReferensiTransfer
  ) {
    return res.status(400).json({
      success: false,
      message:
        'withdrawalId, adminId, dan nomorReferensiTransfer wajib diisi.',
    });
  }

  if (
    !mongoose.Types.ObjectId.isValid(adminId)
  ) {
    return res.status(400).json({
      success: false,
      message: 'adminId tidak valid.',
    });
  }

  if (!nomorReferensiTransfer.trim()) {
    return res.status(400).json({
      success: false,
      message: 'Nomor referensi transfer tidak boleh kosong.',
    });
  }

  const session = await mongoose.startSession();

  try {
    session.startTransaction();

    const withdrawal = await Withdrawal.findOne({
      withdrawalId,
    }).session(session);

    if (!withdrawal) {
      throw new Error('Data penarikan tidak ditemukan.');
    }

    if (
      ![
        'MENUNGGU_ADMIN',
        'DIPROSES_ADMIN',
      ].includes(withdrawal.status)
    ) {
      throw new Error(
        `Penarikan tidak dapat dikonfirmasi. Status saat ini: ${withdrawal.status}.`
      );
    }

    const wallet = await Wallet.findById(
      withdrawal.walletId
    ).session(session);

    if (!wallet) {
      throw new Error('Wallet seller tidak ditemukan.');
    }

    /*
     * Saldo sudah dikurangi ketika WD dibuat.
     * Di sini kita hanya mencatat bahwa uang sudah
     * benar-benar ditransfer oleh Admin.
     */
    wallet.totalDitarik += withdrawal.jumlah;

    withdrawal.status = 'SUDAH_DITRANSFER';
    withdrawal.ditransferOleh = adminId;
    withdrawal.waktuTransfer = new Date();
    withdrawal.nomorReferensiTransfer =
      nomorReferensiTransfer.trim();
    withdrawal.buktiTransferUrl =
      buktiTransferUrl || null;
    withdrawal.catatanAdmin =
      catatanAdmin || '';

    await wallet.save({ session });
    await withdrawal.save({ session });

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message:
        'Penarikan ditandai sudah ditransfer oleh Admin.',
      data: {
        withdrawalId: withdrawal.withdrawalId,
        jumlah: withdrawal.jumlah,
        status: withdrawal.status,
        nomorReferensiTransfer:
          withdrawal.nomorReferensiTransfer,
        waktuTransfer:
          withdrawal.waktuTransfer,
      },
    });
  } catch (error) {
    await session.abortTransaction();

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  } finally {
    await session.endSession();
  }
};

/*
|--------------------------------------------------------------------------
| ADMIN MENOLAK PENARIKAN
|--------------------------------------------------------------------------
| Saldo dikembalikan ke saldoTersedia karena Admin belum
| melakukan transfer.
|--------------------------------------------------------------------------
*/
exports.tolakPenarikan = async (req, res) => {
  const {
    withdrawalId,
    adminId,
    catatanAdmin,
  } = req.body;

  if (!withdrawalId || !adminId) {
    return res.status(400).json({
      success: false,
      message: 'withdrawalId dan adminId wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(adminId)) {
    return res.status(400).json({
      success: false,
      message: 'adminId tidak valid.',
    });
  }

  const session = await mongoose.startSession();

  try {
    session.startTransaction();

    const withdrawal = await Withdrawal.findOne({
      withdrawalId,
    }).session(session);

    if (!withdrawal) {
      throw new Error('Data penarikan tidak ditemukan.');
    }

    if (
      ![
        'MENUNGGU_ADMIN',
        'DIPROSES_ADMIN',
      ].includes(withdrawal.status)
    ) {
      throw new Error(
        `Penarikan tidak dapat ditolak. Status saat ini: ${withdrawal.status}.`
      );
    }

    const wallet = await Wallet.findById(
      withdrawal.walletId
    ).session(session);

    if (!wallet) {
      throw new Error('Wallet seller tidak ditemukan.');
    }

    // Kembalikan dana ke saldo tersedia.
    wallet.saldoTersedia += withdrawal.jumlah;

    withdrawal.status = 'DITOLAK';
    withdrawal.ditransferOleh = adminId;
    withdrawal.catatanAdmin =
      catatanAdmin ||
      'Penarikan ditolak oleh Admin.';

    await wallet.save({ session });
    await withdrawal.save({ session });

    await session.commitTransaction();

    return res.status(200).json({
      success: true,
      message:
        'Penarikan ditolak dan saldo dikembalikan ke seller.',
      data: {
        withdrawalId: withdrawal.withdrawalId,
        status: withdrawal.status,
        saldoTersedia: wallet.saldoTersedia,
      },
    });
  } catch (error) {
    await session.abortTransaction();

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  } finally {
    await session.endSession();
  }
};

/*
|--------------------------------------------------------------------------
| SELLER MELIHAT RIWAYAT PENARIKAN
|--------------------------------------------------------------------------
*/
exports.riwayatPenarikanSeller = async (req, res) => {
  const { sellerId } = req.params;

  if (!sellerId || !mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  try {
    const withdrawals = await Withdrawal.find({
      sellerId,
    }).sort({
      createdAt: -1,
    });

    return res.status(200).json({
      success: true,
      total: withdrawals.length,
      data: withdrawals,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil riwayat penarikan.',
      error: error.message,
    });
  }
};
