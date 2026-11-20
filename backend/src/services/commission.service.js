const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// نسبة عمولة الشركة من رسوم التوصيل
const COMMISSION_RATE = 0.20; // 20%

/**
 * يحسب ويسجل العمولة بعد إتمام الطلب
 * يستخدم Double-Entry Ledger بالضبط زي ما عملناه في الـ Schema
 */
async function processOrderCommission(orderId) {
  const order = await prisma.order.findUnique({ where: { id: orderId } });
  if (!order || !order.driverId) return null;

  const deliveryFee = order.price;
  const companyCommission = parseFloat((deliveryFee * COMMISSION_RATE).toFixed(2));
  const driverNet = parseFloat((deliveryFee - companyCommission).toFixed(2));

  // Transaction ذرية — كل الـ ledger entries بتتسجل مع بعض أو مش بتتسجل
  await prisma.$transaction([
    // 1. سجل أن السائق جمع كاش من العميل
    prisma.ledgerTransaction.create({
      data: {
        driverId: order.driverId,
        amount: deliveryFee,
        type: 'COD_COLLECTED',
        description: `تحصيل رسوم توصيل - طلب #${orderId}`,
      },
    }),

    // 2. سجل خصم العمولة المستحقة للشركة
    prisma.ledgerTransaction.create({
      data: {
        driverId: order.driverId,
        amount: companyCommission,
        type: 'COMMISSION',
        description: `عمولة الشركة 20% - طلب #${orderId}`,
      },
    }),

    // 3. أضف صافي الكسب لمحفظة السائق
    prisma.driverProfile.update({
      where: { userId: order.driverId },
      data: { walletBalance: { increment: driverNet } },
    }),
  ]);

  console.log(`💰 [Commission] Order ${orderId} | Driver earns: ${driverNet} EGP | Company: ${companyCommission} EGP`);

  return { deliveryFee, companyCommission, driverNet };
}

/**
 * استعلام ميزان السائق (ما جمعه - ما عليه)
 */
async function getDriverBalance(driverId) {
  const profile = await prisma.driverProfile.findUnique({
    where: { userId: driverId },
    select: { walletBalance: true, maxDebtLimit: true },
  });

  if (!profile) return null;

  return {
    balance: profile.walletBalance,
    maxDebtLimit: profile.maxDebtLimit,
    isInDebt: profile.walletBalance < 0,
    canAcceptOrders: profile.walletBalance > -profile.maxDebtLimit,
  };
}

module.exports = { processOrderCommission, getDriverBalance };
