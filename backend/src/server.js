require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');

const { setupSocketHandlers } = require('./socket/socketHandlers');
const authRoutes = require('./routes/auth.routes');
const orderRoutes = require('./routes/order.routes');
const driverRoutes = require('./routes/driver.routes');
const ledgerRoutes = require('./routes/ledger.routes');
const { errorHandler } = require('./middleware/errorHandler');
const { authenticateToken } = require('./middleware/auth.middleware');

const path = require('path');

const app = express();
const httpServer = http.createServer(app);

// تقديم لوحة تحكم الويب للدكان
app.use(express.static(path.join(__dirname, '../public')));

// ─── Socket.io ────────────────────────────────────────────────────────────────
const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  transports: ['websocket', 'polling'],
});
setupSocketHandlers(io);

// ─── Global Middleware ─────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Rate limiting — حماية من الـ Spam
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 دقيقة
  max: 100,
  message: { error: 'طلبات كتير جداً، انتظر شوية' },
});
app.use('/api/', limiter);

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/orders', authenticateToken, orderRoutes);
app.use('/api/drivers', authenticateToken, driverRoutes);
app.use('/api/ledger', authenticateToken, ledgerRoutes);

// Make io accessible in routes via req.app.get('io')
app.set('io', io);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'Al-Tayer Backend', time: new Date().toISOString() });
});

// ─── Error Handler ────────────────────────────────────────────────────────────
app.use(errorHandler);

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`🚀 Al-Tayer Server running on port ${PORT}`);
  console.log(`🔗 Socket.io ready`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = { app, io };
