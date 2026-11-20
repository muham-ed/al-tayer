const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { getDriverBalance } = require('../services/commission.service');
const { requireRole } = require('../middleware/auth.middleware');

const prisma = new PrismaClient();

// ─── GET /api/drivers/me ──────────────────────────────────────────────────────
// المندوب يشوف بروفايله وميزانه
router.get('/me', requireRole('DRIVER'), async (req, res, next) => {
  try {
    const driverId = req.user.userId;
    const profile = await prisma.driverProfile.findUnique({
      where: { userId: driverId },
      include: { user: { select: { name: true, phone: true } } },
    });

    if (!profile) return res.status(404).json({ error: 'بروفايل المندوب مش موجود' });

    const balance = await getDriverBalance(driverId);

    res.json({ success: true, profile, balance });
  } catch (err) {
    next(err);
  }
});

// ─── PATCH /api/drivers/me/status ────────────────────────────────────────────
// المندوب يغير حالته (online/offline)
router.patch('/me/status', requireRole('DRIVER'), async (req, res, next) => {
  try {
    const { isOnline } = req.body;
    const driverId = req.user.userId;

    const profile = await prisma.driverProfile.update({
      where: { userId: driverId },
      data: { isOnline: Boolean(isOnline) },
    });

    // بث التحديث للـ Admin Dashboard
    const io = req.app.get('io');
    if (io) {
      io.emit('driver_status_changed', { driverId, isOnline: profile.isOnline });
    }

    res.json({ success: true, isOnline: profile.isOnline });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/drivers/me/orders ──────────────────────────────────────────────
// تاريخ الطلبات للمندوب
router.get('/me/orders', requireRole('DRIVER'), async (req, res, next) => {
  try {
    const driverId = req.user.userId;
    const orders = await prisma.order.findMany({
      where: { driverId },
      include: { customer: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json({ success: true, orders });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/drivers/me/ledger ──────────────────────────────────────────────
// كشف الحساب المفصل للمندوب
router.get('/me/ledger', requireRole('DRIVER'), async (req, res, next) => {
  try {
    const driverId = req.user.userId;
    const transactions = await prisma.ledgerTransaction.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const balance = await getDriverBalance(driverId);
    res.json({ success: true, transactions, balance });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
