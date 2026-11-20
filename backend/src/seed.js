require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Al-Tayer Database Seed...');

  // 1. إنشاء حساب أدمن
  const admin = await prisma.user.upsert({
    where: { phone: '01000000001' },
    update: {},
    create: {
      phone: '01000000001',
      name: 'مدير منصة ع الطاير',
      role: 'ADMIN',
    },
  });
  console.log('👤 Admin created:', admin.name);

  // 2. إنشاء كابتن افتراضي
  const driverUser = await prisma.user.upsert({
    where: { phone: '01009988776' },
    update: {},
    create: {
      phone: '01009988776',
      name: 'كابتن محمود ع الطاير',
      role: 'DRIVER',
    },
  });

  const driverProfile = await prisma.driverProfile.upsert({
    where: { userId: driverUser.id },
    update: {},
    create: {
      userId: driverUser.id,
      vehicleModel: 'موتوسيكل هوجان 2023',
      licenseNumber: 'اسكندرية 98453',
      isOnline: true,
      rating: 4.95,
      maxDebtLimit: 300.0,
      walletBalance: 0.0,
      currentLocation: JSON.stringify({ latitude: 31.1180, longitude: 29.7820 }),
    },
  });
  console.log('🏍️ Driver created:', driverUser.name, 'Profile ID:', driverProfile.id);

  // 3. إنشاء عميل تجريبي
  const customer = await prisma.user.upsert({
    where: { phone: '01012345678' },
    update: {},
    create: {
      phone: '01012345678',
      name: 'أحمد الإسكندراني',
      role: 'CUSTOMER',
    },
  });
  console.log('🛒 Customer created:', customer.name);

  console.log('\n✅ Database seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
