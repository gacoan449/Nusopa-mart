function allowRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User belum terautentikasi.',
      });
    }

    if (!req.user.role) {
      return res.status(403).json({
        success: false,
        message: 'Role user tidak ditemukan.',
      });
    }

    const normalizedRole = String(
      req.user.role
    ).toUpperCase();

    const normalizedAllowedRoles =
      allowedRoles.map((role) =>
        String(role).toUpperCase()
      );

    if (
      !normalizedAllowedRoles.includes(
        normalizedRole
      )
    ) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki hak akses untuk tindakan ini.',
      });
    }

    next();
  };
}

/*
|--------------------------------------------------------------------------
| SHORTCUT ROLE
|--------------------------------------------------------------------------
*/

const adminOnly = allowRoles('ADMIN');

const sellerOnly = allowRoles('SELLER');

const buyerOnly = allowRoles('PEMBELI', 'BUYER');

const adminOrSeller = allowRoles(
  'ADMIN',
  'SELLER'
);

module.exports = {
  allowRoles,
  adminOnly,
  sellerOnly,
  buyerOnly,
  adminOrSeller,
};
