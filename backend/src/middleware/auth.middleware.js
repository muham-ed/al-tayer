const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

/**
 * Middleware: يتحقق من JWT Token في كل request محمية
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>

  if (!token) {
    return res.status(401).json({ error: 'مش متسجل دخول، برجاء تسجيل الدخول أولاً' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // { userId, phone, role }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'انتهت صلاحية الجلسة، ادخل من تاني' });
    }
    return res.status(403).json({ error: 'Token غلط أو محرف' });
  }
}

/**
 * Middleware: يسمح بـ Roles معينة بس
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return res.status(403).json({ error: 'مش مسموح لك بالعملية دي' });
    }
    next();
  };
}

module.exports = { authenticateToken, requireRole };
