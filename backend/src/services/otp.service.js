/**
 * OTP Service — ولو مكنتش عامل Vonage/Twilio بعد،
 * هنستخدم نظام OTP محلي مع Redis cache.
 * لما تشتري SMS provider، بس استبدل sendSmsOtp().
 */

const Redis = require('ioredis');

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  lazyConnect: true,
});

redis.on('error', (err) => {
  console.warn('⚠️ [Redis] Connection issue — OTP will fallback to in-memory:', err.message);
});

// In-memory fallback لو Redis مش شغال
const inMemoryStore = new Map();

const OTP_EXPIRE_SECONDS = 300; // 5 دقائق

/**
 * يولد OTP من 4 أرقام ويحفظه
 */
async function generateAndStoreOtp(phone) {
  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  const key = `otp:${phone}`;

  try {
    await redis.setex(key, OTP_EXPIRE_SECONDS, otp);
  } catch {
    // Redis مش متصل — استخدم in-memory
    inMemoryStore.set(key, { otp, expiresAt: Date.now() + OTP_EXPIRE_SECONDS * 1000 });
  }

  return otp;
}

/**
 * يتحقق من OTP ويحذفه لو صح (single-use)
 */
async function verifyOtp(phone, inputOtp) {
  const key = `otp:${phone}`;
  let storedOtp = null;

  try {
    storedOtp = await redis.get(key);
  } catch {
    // fallback to in-memory
    const entry = inMemoryStore.get(key);
    if (entry && Date.now() < entry.expiresAt) {
      storedOtp = entry.otp;
    }
  }

  if (!storedOtp) {
    return { valid: false, reason: 'الكود انتهت صلاحيته أو مش موجود' };
  }

  if (storedOtp !== inputOtp) {
    return { valid: false, reason: 'الكود غلط' };
  }

  // حذف بعد الاستخدام
  try {
    await redis.del(key);
  } catch {
    inMemoryStore.delete(key);
  }

  return { valid: true };
}

/**
 * إرسال SMS — استبدل الجزه ده بـ Vonage/Twilio لما تجهز
 * في الوقت الحالي: بيطبع في الـ console للتطوير
 */
async function sendSmsOtp(phone, otp) {
  if (process.env.NODE_ENV === 'production' && process.env.VONAGE_API_KEY) {
    // Vonage SMS
    const { Vonage } = require('@vonage/server-sdk');
    const vonage = new Vonage({
      apiKey: process.env.VONAGE_API_KEY,
      apiSecret: process.env.VONAGE_API_SECRET,
    });
    await vonage.sms.send({
      to: `2${phone}`, // مصر كود
      from: 'AlTayer',
      text: `كود تحقق ع الطاير: ${otp} - صالح لمدة 5 دقائق فقط`,
    });
    console.log(`📱 [OTP] SMS sent to ${phone}`);
  } else {
    // Dev mode — اطبع في الـ console
    console.log(`\n🔑 =============================`);
    console.log(`📱 OTP for ${phone}: ${otp}`);
    console.log(`🔑 =============================\n`);
  }
}

module.exports = { generateAndStoreOtp, verifyOtp, sendSmsOtp };
