import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../order/domain/models/order_model.dart';

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {}

class DriverReadyState extends DriverState {
  final bool isOnline;
  final List<OrderModel> availableOrders;
  final OrderModel? activeOrder;
  final double? currentLat;
  final double? currentLng;
  final double todayEarnings; // أرباح الكابتن اليومية لتشجيعه

  const DriverReadyState({
    required this.isOnline,
    required this.availableOrders,
    this.activeOrder,
    this.currentLat,
    this.currentLng,
    this.todayEarnings = 145.0,
  });

  DriverReadyState copyWith({
    bool? isOnline,
    List<OrderModel>? availableOrders,
    OrderModel? activeOrder,
    bool clearActiveOrder = false,
    double? currentLat,
    double? currentLng,
    double? todayEarnings,
  }) {
    return DriverReadyState(
      isOnline: isOnline ?? this.isOnline,
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      todayEarnings: todayEarnings ?? this.todayEarnings,
    );
  }

  @override
  List<Object?> get props => [isOnline, availableOrders, activeOrder, currentLat, currentLng, todayEarnings];
}

class DriverCubit extends Cubit<DriverState> {
  final SocketService socketService;
  final LocationService locationService;

  DriverCubit({
    required this.socketService,
    required this.locationService,
  }) : super(DriverInitial()) {
    initDriver();
  }

  void initDriver() {
    final mockAvailableOrders = [
      OrderModel(
        id: 'ORD-9901',
        customerId: 'CUST-1',
        customerName: 'كريم محمود',
        customerPhone: '01234567890',
        type: OrderType.errand,
        status: OrderStatus.pending,
        itemsDescription: '2 كيلو لبن + علبة زبادي من لبانة السلام',
        pickupLocation: const LocationPoint(
          latitude: 31.1180,
          longitude: 29.7820,
          address: 'البيطاش - شارع عين شمس',
        ),
        dropoffLocation: const LocationPoint(
          latitude: 31.1230,
          longitude: 29.7780,
          address: 'البيطاش - شارع الحنفية',
          landmark: 'بجوار مدرسة الأورمان - برج النور',
          buildingDetails: 'الدور 3 شقة 5',
        ),
        distanceKm: 2.1,
        deliveryFee: 25.0,
        estimatedCost: 75.0,
        tip: 5.0,
        createdAt: DateTime.now(),
      ),
      OrderModel(
        id: 'ORD-9902',
        customerId: 'CUST-2',
        customerName: 'أحمد نبيل',
        customerPhone: '01122334455',
        type: OrderType.pharmacy,
        status: OrderStatus.pending,
        itemsDescription: 'بنادول اكسترا + شاش وقطن من صيدلية خليل',
        pickupLocation: const LocationPoint(
          latitude: 31.1150,
          longitude: 29.7850,
          address: 'البيطاش - الشارع الرئيسي',
        ),
        dropoffLocation: const LocationPoint(
          latitude: 31.1270,
          longitude: 29.7710,
          address: 'العجمي - الهانوفيل',
          landmark: 'أمام بنك الإسكندرية مباشرة',
        ),
        distanceKm: 4.8,
        deliveryFee: 35.0,
        estimatedCost: 110.0,
        tip: 10.0,
        createdAt: DateTime.now(),
      ),
    ];

    emit(DriverReadyState(
      isOnline: true,
      availableOrders: mockAvailableOrders,
    ));

    socketService.onNewOrderAvailable((data) {
      if (state is DriverReadyState) {
        final current = state as DriverReadyState;
        final newOrder = OrderModel.fromJson(data);
        emit(current.copyWith(
          availableOrders: [newOrder, ...current.availableOrders],
        ));
      }
    });
  }

  void toggleOnlineStatus(String driverId) {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      final newStatus = !current.isOnline;
      socketService.setDriverOnlineStatus(newStatus, driverId);

      if (newStatus) {
        _startSendingLocationUpdates();
      } else {
        locationService.stopLocationUpdates();
      }

      emit(current.copyWith(isOnline: newStatus));
    }
  }

  void _startSendingLocationUpdates() {
    locationService.startLocationUpdates(
      onLocationChanged: (pos) {
        if (state is DriverReadyState) {
          final current = state as DriverReadyState;
          emit(current.copyWith(
            currentLat: pos.latitude,
            currentLng: pos.longitude,
          ));

          if (current.activeOrder != null) {
            socketService.sendDriverLocation(
              orderId: current.activeOrder!.id,
              lat: pos.latitude,
              lng: pos.longitude,
              bearing: pos.heading,
              driverId: 'DRV-1',
            );
          }
        }
      },
    );
  }

  void acceptOrder(OrderModel order) {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      final updatedOrder = order.copyWith(
        status: OrderStatus.accepted,
        driverId: 'DRV-1',
        driverName: 'كابتن محمود ع الطاير',
        driverPhone: '01009988776',
      );

      socketService.joinOrderRoom(order.id);
      final updatedAvailable = current.availableOrders.where((o) => o.id != order.id).toList();

      emit(current.copyWith(
        availableOrders: updatedAvailable,
        activeOrder: updatedOrder,
      ));
    }
  }

  void recordReceiptAndMoveToDelivery({
    required double actualReceiptCost,
    String? receiptNote,
  }) {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      if (current.activeOrder == null) return;

      final updatedOrder = current.activeOrder!.copyWith(
        status: OrderStatus.pickedUp,
        actualReceiptCost: actualReceiptCost,
        receiptNote: receiptNote,
      );

      // بث التحديث للعميل عبر السوكيت ليرى الفاتورة فوراً قبل وصول المندوب
      socketService.onOrderStatusChange((_, __) {});

      emit(current.copyWith(activeOrder: updatedOrder));
    }
  }

  void updateOrderStatus(OrderStatus newStatus) {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      if (current.activeOrder == null) return;

      if (newStatus == OrderStatus.delivered) {
        final feeEarned = current.activeOrder!.deliveryFee + current.activeOrder!.tip;
        emit(current.copyWith(
          clearActiveOrder: true,
          todayEarnings: current.todayEarnings + feeEarned,
        ));
      } else if (newStatus == OrderStatus.cancelled) {
        emit(current.copyWith(clearActiveOrder: true));
      } else {
        emit(current.copyWith(
          activeOrder: current.activeOrder!.copyWith(status: newStatus),
        ));
      }
    }
  }
}
