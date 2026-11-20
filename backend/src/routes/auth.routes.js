const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { generateAndStoreOtp, verifyOtp, sendSmsOtp } = require('../services/otp.service');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES = '30d';

// ─── POST /api/auth/send-otp ──────────────────────────────────────────────────
router.post('/send-otp', async (req, res, next) => {
  try {
    const { phone, role } = req.body;

    if (!phone || !/^01[0-9]{9}$/.test(phone)) {
      return res.status(400).json({ error: 'رقم الهاتف مش صح، لازم يبدأ بـ 01 ويكون 11 رقم' });
    }

    if (!['customer', 'driver'].includes(role)) {
      return res.status(400).json({ error: 'الدور غلط، اختر customer أو driver' });
    }

    const otp = await generateAndStoreOtp(phone);
    await sendSmsOtp(phone, otp);

    res.json({
      success: true,
      message: `تم إرسال كود التحقق على ${phone}`,
      // بس في البيئة التطوير — شيلها في production
      ...(process.env.NODE_ENV !== 'production' && { devOtp: otp }),
    });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/auth/verify-otp ────────────────────────────────────────────────
router.post('/verify-otp', async (req, res, next) => {
  try {
    const { phone, otp, role, name } = req.body;

    if (!phone || !otp || !role) {
      return res.status(400).json({ error: 'الهاتف والكود والدور مطلوبين' });
    }

    // تحقق من OTP
    const result = await verifyOtp(phone, otp);
    if (!result.valid) {
      return res.status(401).json({ error: result.reason });
    }

    // جيب أو أنشئ User
    let user = await prisma.user.findUnique({ where: { phone } });

    const prismaRole = role === 'driver' ? 'DRIVER' : 'CUSTOMER';
    const finalName = name?.trim() || (role === 'driver' ? 'مندوب ع الطاير' : 'عميل ع الطاير');

    if (!user) {
      user = await prisma.user.create({
        data: { phone, name: finalName, role: prismaRole },
      });

      // لو مندوب جديد، اعمله Profile تلقائي
      if (prismaRole === 'DRIVER') {
        await prisma.driverProfile.create({
          data: { userId: user.id },
        });
      }
    } else {
      // حدّث الاسم لو اتغير
      if (name?.trim() && name.trim() !== user.name) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { name: name.trim() },
        });
      }
    }

    // ولّد JWT
    const token = jwt.sign(
      { userId: user.id, phone: user.phone, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role.toLowerCase(),
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
