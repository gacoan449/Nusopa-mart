const mongoose = require('mongoose');
const Order = require('../../models/Order');

/*
|--------------------------------------------------------------------------
| SELLER INPUT PENGIRIMAN
|--------------------------------------------------------------------------
| Wajib:
| - Nama ekspedisi
| - Nomor resi
| - Biaya ekspedisi
|
| Dana Rekber tetap TERKUNCI sampai buyer menerima barang.
|--------------------------------------------------------------------------
*/
exports.kirimPesanan = async (req, res) => {
  const {
    orderId,
    sellerId,
    namaEkspedisi,
    nomorResi,
    biayaEkspedisi,
  } = req.body;

  if (
    !orderId ||
    !sellerId ||
    !namaEkspedisi ||
    !nomorResi ||
    biayaEkspedisi === undefined ||
    biayaEkspedisi === null
  ) {
    return res.status(400).json({
      success: false,
      message:
        'orderId, sellerId, namaEkspedisi, nomorResi, dan biayaEkspedisi wajib diisi.',
    });
  }

  if (!mongoose.Types.ObjectId.isValid(sellerId)) {
    return res.status(400).json({
      success: false,
      message: 'sellerId tidak valid.',
    });
  }

  const ongkir = Number(biayaEkspedisi);

  if (!Number.isFinite(ongkir) || ongkir < 0) {
    return res.status(400).json({
      success: false,
      message: 'Biaya ekspedisi tidak valid.',
    });
  }

  try {
    const order = await Order.findOne({ orderId });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Pesanan tidak ditemukan.',
      });
    }

    if (order.sellerId.toString() !== sellerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Anda bukan seller dari pesanan ini.',
      });
    }

    if (order.statusDana !== 'TERKUNCI') {
      return res.status(400).json({
        success: false,
        message: 'Pesanan belum memiliki dana Rekber yang terkunci.',
      });
    }

    if (
      ![
        'PEMBAYARAN_DIVERIFIKASI',
        'DIPROSES_SELLER',
      ].includes(order.statusPesanan)
    ) {
      return res.status(400).json({
        success: false,
        message:
          `Pesanan tidak dapat dikirim pada status ${order.statusPesanan}.`,
      });
    }

    if (order.nomorResi) {
      return res.status(400).json({
        success: false,
        message: 'Nomor resi untuk pesanan ini sudah tersimpan.',
      });
    }

    order.namaEkspedisi = namaEkspedisi.trim();
    order.nomorResi = nomorResi.trim();
    order.biayaEkspedisi = ongkir;
    order.statusPesanan = 'DIKIRIM';
    order.waktuDikirim = new Date();

    await order.save();

    return res.status(200).json({
      success: true,
      message: 'Data pengiriman berhasil disimpan.',
      data: {
        orderId: order.orderId,
        namaEkspedisi: order.namaEkspedisi,
        nomorResi: order.nomorResi,
        biayaEkspedisi: order.biayaEkspedisi,
        statusPesanan: order.statusPesanan,
        statusDana: order.statusDana,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal menyimpan data pengiriman.',
      error: error.message,
    });
  }
};
