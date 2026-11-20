const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { requireRole } = require('../middleware/auth.middleware');

const prisma = new PrismaClient();

// ─── POST /api/ledger/topup ───────────────────────────────────────────────────
// الأدمن يشحن محفظة مندوب (بعد ما يستلم كاش منه)
router.post('/topup', requireRole('ADMIN'), async (req, res, next) => {
  try {
    const { driverId, amount, description } = req.body;

    if (!driverId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'بيانات الشحن ناقصة' });
    }

    await prisma.$transaction([
      prisma.ledgerTransaction.create({
        data: {
          driverId,
          amount: parseFloat(amount),
          type: 'TOPUP',
          description: description || 'شحن محفظة',
        },
      }),
      prisma.driverProfile.update({
        where: { userId: driverId },
        data: { walletBalance: { decrement: parseFloat(amount) } }, // بيخصم من دينه
      }),
    ]);

    res.json({ success: true, message: `تم تسجيل دفع ${amount} ج.م من المندوب` });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/ledger/summary ──────────────────────────────────────────────────
// الأدمن يشوف كشف حساب كل المناديب
router.get('/summary', requireRole('ADMIN'), async (req, res, next) => {
  try {
    const drivers = await prisma.driverProfile.findMany({
      include: {
        user: { select: { name: true, phone: true } },
      },
      orderBy: { walletBalance: 'asc' }, // الأكتر دين أول
    });

    const summary = drivers.map((d) => ({
      driverId: d.userId,
      name: d.user.name,
      phone: d.user.phone,
      walletBalance: d.walletBalance,
      maxDebtLimit: d.maxDebtLimit,
      isInDebt: d.walletBalance < 0,
      canAcceptOrders: d.walletBalance > -d.maxDebtLimit,
      rating: d.rating,
      isOnline: d.isOnline,
    }));

    res.json({ success: true, summary });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
