import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  IO.Socket? _socket;
  bool isConnected = false;

  Future<void> init({String? customBaseUrl}) async {
    final String socketUrl = customBaseUrl ?? 'http://10.0.2.2:3000';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(2000)
        .build(),
    );

    _socket?.onConnect((_) {
      isConnected = true;
      debugPrint('⚡ [SocketService] Connected to Real-Time Server ($socketUrl)');
    });

    _socket?.onConnectError((data) {
      isConnected = false;
      debugPrint('❌ [SocketService] Connection Error: $data');
    });

    _socket?.onDisconnect((_) {
      isConnected = false;
      debugPrint('🔌 [SocketService] Disconnected');
    });
  }

  void joinOrderRoom(String orderId) {
    _socket?.emit('join_order', orderId);
  }

  void joinDriverRoom(String driverId) {
    _socket?.emit('join_driver_room', driverId);
  }

  void setDriverOnlineStatus(bool isOnline, String driverId) {
    if (isOnline) {
      _socket?.emit('driver_online', {'driverId': driverId});
    } else {
      _socket?.emit('driver_offline', {'driverId': driverId});
    }
  }

  void sendDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
    double bearing = 0.0,
    String? driverId,
  }) {
    _socket?.emit('update_location', {
      'orderId': orderId,
      'driverId': driverId,
      'lat': lat,
      'lng': lng,
      'bearing': bearing,
    });
  }

  void onLocationUpdate(Function(double lat, double lng, double bearing) callback) {
    _socket?.off('location_updated');
    _socket?.on('location_updated', (data) {
      if (data != null) {
        final double lat = (data['lat'] as num).toDouble();
        final double lng = (data['lng'] as num).toDouble();
        final double bearing = ((data['bearing'] ?? 0.0) as num).toDouble();
        callback(lat, lng, bearing);
      }
    });
  }

  void onOrderStatusChange(Function(String status, Map<String, dynamic> extra) callback) {
    _socket?.off('status_changed');
    _socket?.on('status_changed', (data) {
      if (data != null && data['status'] != null) {
        callback(data['status'].toString(), Map<String, dynamic>.from(data));
      }
    });
  }

  void onNewOrderAvailable(Function(Map<String, dynamic> orderData) callback) {
    _socket?.off('new_order_available');
    _socket?.on('new_order_available', (data) {
      if (data != null) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
