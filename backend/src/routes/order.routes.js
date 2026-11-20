const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { processOrderCommission } = require('../services/commission.service');

const prisma = new PrismaClient();

// ─── POST /api/orders ─────────────────────────────────────────────────────────
// العميل بيعمل طلب جديد
router.post('/', async (req, res, next) => {
  try {
    const { customerId, pickupLocation, dropoffLocation, price, itemsDescription, estimatedCost, tip } = req.body;

    // التأكد إن الـ customerId هو نفس المتسجل
    if (req.user.userId !== customerId && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'مش مسموح تعمل طلب لحساب تاني' });
    }

    const order = await prisma.order.create({
      data: {
        customerId,
        pickupLocation: JSON.stringify(pickupLocation),
        dropoffLocation: JSON.stringify(dropoffLocation),
        price: parseFloat(price),
        itemsDescription: itemsDescription || null,
        estimatedCost: estimatedCost ? parseFloat(estimatedCost) : 0,
        tip: tip ? parseFloat(tip) : 0,
        status: 'PENDING',
      },
      include: {
        customer: { select: { name: true, phone: true } },
      },
    });

    // بث الطلب الجديد فوراً لجميع المناديب المتصلين عبر Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to('drivers_online').emit('new_order_available', {
        id: order.id,
        customerId: order.customerId,
        customerName: order.customer?.name || 'عميل ع الطاير',
        customerPhone: order.customer?.phone || '',
        itemsDescription: order.itemsDescription || 'مشوار طلبات',
        dropoffLocation: dropoffLocation,
        pickupLocation: pickupLocation,
        deliveryFee: order.price,
        estimatedCost: order.estimatedCost,
        tip: order.tip,
        createdAt: order.createdAt.toISOString(),
      });
    }

    res.status(201).json({ success: true, order });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/orders/available ────────────────────────────────────────────────
// المندوب يشوف الطلبات المتاحة
router.get('/available', async (req, res, next) => {
  try {
    const orders = await prisma.order.findMany({
      where: { status: 'PENDING', driverId: null },
      include: { customer: { select: { name: true, phone: true } } },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    res.json({ success: true, orders });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/orders/:id ──────────────────────────────────────────────────────
router.get('/:id', async (req, res, next) => {
  try {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        customer: { select: { name: true, phone: true } },
        driver: { select: { user: { select: { name: true, phone: true } } } },
      },
    });

    if (!order) return res.status(404).json({ error: 'مش لاقي الطلب ده' });
    res.json({ success: true, order });
  } catch (err) {
    next(err);
  }
});

// ─── PATCH /api/orders/:id/status ────────────────────────────────────────────
// تحديث حالة الطلب (من المندوب أو الأدمن)
router.patch('/:id/status', async (req, res, next) => {
  try {
    const { status, actualReceiptCost, receiptNote } = req.body;
    const { id } = req.params;

    const allowedStatuses = ['ACCEPTED', 'AT_STORE', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ error: 'الحالة دي مش معروفة' });
    }

    const updateData = { status };
    if (actualReceiptCost !== undefined) {
      updateData.actualReceiptCost = parseFloat(actualReceiptCost);
    }

    const order = await prisma.order.update({
      where: { id },
      data: updateData,
    });

    // لو اتسلّم — احسب العمولة فوراً
    if (status === 'DELIVERED') {
      await processOrderCommission(id);
    }

    // بث التحديث لكل اللي في غرفة الطلب ده عبر Socket.io
    // (io بتجي من السيرفر main — نعملها available عبر req.app)
    const io = req.app.get('io');
    if (io) {
      io.to(`order:${id}`).emit('status_changed', {
        status: status.toLowerCase(),
        orderId: id,
        actualReceiptCost: order.actualReceiptCost,
        receiptNote,
        driverName: req.user.name,
      });
    }

    res.json({ success: true, order });
  } catch (err) {
    next(err);
  }
});

// ─── PATCH /api/orders/:id/accept ────────────────────────────────────────────
// المندوب يقبل الطلب
router.patch('/:id/accept', async (req, res, next) => {
  try {
    const driverId = req.user.userId;
    const { id } = req.params;

    // تأكد إن الطلب لسه pending
    const existing = await prisma.order.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'الطلب مش موجود' });
    if (existing.status !== 'PENDING') {
      return res.status(409).json({ error: 'الطلب ده اتاخد قبل كده' });
    }

    const order = await prisma.order.update({
      where: { id },
      data: { driverId, status: 'ACCEPTED' },
      include: { customer: { select: { name: true, phone: true } } },
    });

    res.json({ success: true, order });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
