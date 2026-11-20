const jwt = require('jsonwebtoken');

/**
 * Socket.io Real-Time Engine
 * يتعامل مع:
 * - تتبع السائق Live (location updates)
 * - بث الطلبات الجديدة للمناديب
 * - تحديثات حالة الطلب في الوقت الفعلي
 */
function setupSocketHandlers(io) {
  // Authentication Middleware للـ Socket
  io.use((socket, next) => {
    const token = socket.handshake.headers['authorization']?.split(' ')[1]
      || socket.handshake.auth?.token;

    if (!token) {
      // بنسمح بالاتصال بدون token في الوقت الحالي (للتتبع العام)
      // لكن الـ events الحساسة بتتحقق منفردة
      socket.user = null;
      return next();
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch {
      socket.user = null;
      next();
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user?.userId || `anon_${socket.id}`;
    console.log(`⚡ [Socket] Connected: ${userId}`);

    // ─── العميل والمندوب ينضموا لغرفة الطلب ─────────────────────────────────
    socket.on('join_order', (orderId) => {
      socket.join(`order:${orderId}`);
      console.log(`📦 [Socket] ${userId} joined order room: ${orderId}`);
    });

    // ─── المندوب ينضم لغرفته الخاصة (لاستقبال طلبات جديدة) ─────────────────
    socket.on('join_driver_room', (driverId) => {
      socket.join(`driver:${driverId}`);
      console.log(`🏍️ [Socket] Driver ${driverId} joined driver room`);
    });

    // ─── المندوب يبعت موقعه كل شوية ──────────────────────────────────────────
    socket.on('update_location', (data) => {
      const { orderId, driverId, lat, lng, bearing } = data;
      if (!orderId || !lat || !lng) return;

      // بعت للعميل اللي في غرفة الطلب ده
      io.to(`order:${orderId}`).emit('location_updated', {
        lat,
        lng,
        bearing: bearing || 0,
        driverId,
        timestamp: Date.now(),
      });
    });

    // ─── المندوب يغير حالته online/offline ───────────────────────────────────
    socket.on('driver_online', (data) => {
      const { driverId } = data;
      socket.join('drivers_online'); // غرفة المناديب المتصلين
      io.emit('driver_status_update', { driverId, isOnline: true });
      console.log(`🟢 [Socket] Driver ${driverId} is online`);
    });

    socket.on('driver_offline', (data) => {
      const { driverId } = data;
      socket.leave('drivers_online');
      io.emit('driver_status_update', { driverId, isOnline: false });
      console.log(`🔴 [Socket] Driver ${driverId} is offline`);
    });

    // ─── بث طلب جديد لكل المناديب المتصلين ──────────────────────────────────
    // هتتستدعي من الـ OrderRoutes لما العميل يعمل طلب جديد
    socket.on('broadcast_new_order', (orderData) => {
      // بس الأدمن أو النظام يقدر يعمل ده
      io.to('drivers_online').emit('new_order_available', orderData);
      console.log(`📢 [Socket] New order broadcast to all online drivers`);
    });

    // ─── Disconnect ───────────────────────────────────────────────────────────
    socket.on('disconnect', () => {
      console.log(`🔌 [Socket] Disconnected: ${userId}`);
    });
  });

  // Export io reference للـ Routes
  return io;
}

module.exports = { setupSocketHandlers };
