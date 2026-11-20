/**
 * Global error handler — يمسك أي error مش متعامل معاه
 */
function errorHandler(err, req, res, next) {
  console.error('❌ [Error]', err.message, err.stack);

  // Prisma unique constraint violation
  if (err.code === 'P2002') {
    return res.status(409).json({ error: 'البيانات دي موجودة قبل كده' });
  }

  // Prisma record not found
  if (err.code === 'P2025') {
    return res.status(404).json({ error: 'مش لاقي البيانات المطلوبة' });
  }

  const status = err.status || 500;
  const message = err.message || 'حصل خطأ في السيرفر، حاول تاني';

  res.status(status).json({ error: message });
}

module.exports = { errorHandler };
