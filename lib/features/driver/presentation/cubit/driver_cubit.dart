import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/domain/repositories/order_repository.dart';

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

class DriverReadyState extends DriverState {
  final bool isOnline;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final List<OrderModel> availableOrders;
  final OrderModel? activeOrder;
  final double? currentLat;
  final double? currentLng;
  final double todayEarnings;

  const DriverReadyState({
    required this.isOnline,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.availableOrders,
    this.activeOrder,
    this.currentLat,
    this.currentLng,
    this.todayEarnings = 0.0,
  });

  DriverReadyState copyWith({
    bool? isOnline,
    String? driverId,
    String? driverName,
    String? driverPhone,
    List<OrderModel>? availableOrders,
    OrderModel? activeOrder,
    bool clearActiveOrder = false,
    double? currentLat,
    double? currentLng,
    double? todayEarnings,
  }) {
    return DriverReadyState(
      isOnline: isOnline ?? this.isOnline,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      todayEarnings: todayEarnings ?? this.todayEarnings,
    );
  }

  @override
  List<Object?> get props => [
        isOnline,
        driverId,
        driverName,
        driverPhone,
        availableOrders,
        activeOrder,
        currentLat,
        currentLng,
        todayEarnings,
      ];
}

class DriverCubit extends Cubit<DriverState> {
  final SocketService socketService;
  final LocationService locationService;
  final OrderRepository orderRepository;
  final SecureStorageService secureStorage;

  DriverCubit({
    required this.socketService,
    required this.locationService,
    required this.orderRepository,
    required this.secureStorage,
  }) : super(DriverInitial()) {
    initDriver();
  }

  Future<void> initDriver() async {
    final userData = await secureStorage.getUserData();
    final driverId = userData['userId'] ?? 'DRV-ANON';
    final driverName = userData['userName'] ?? 'مندوب ع الطاير';
    final driverPhone = userData['phone'] ?? '';

    emit(DriverReadyState(
      isOnline: true,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      availableOrders: const [],
    ));

    // جلب الطلبات المتاحة الحقيقية من السيرفر
    await fetchAvailableOrders();

    // الانضمام لغرفة السائق الخاصة بالسوكيت
    socketService.joinDriverRoom(driverId);

    // الاستماع للطلبات الجديدة في الوقت الفعلي
    socketService.onNewOrderAvailable((data) {
      if (state is DriverReadyState) {
        final current = state as DriverReadyState;
        try {
          final newOrder = OrderModel.fromJson(data);
          emit(current.copyWith(
            availableOrders: [newOrder, ...current.availableOrders],
          ));
        } catch (_) {}
      }
    });

    _startSendingLocationUpdates();
  }

  Future<void> fetchAvailableOrders() async {
    final result = await orderRepository.getAvailableOrders();
    result.fold(
      (error) => null,
      (orders) {
        if (state is DriverReadyState) {
          final current = state as DriverReadyState;
          emit(current.copyWith(availableOrders: orders));
        }
      },
    );
  }

  void toggleOnlineStatus() {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      final newStatus = !current.isOnline;
      socketService.setDriverOnlineStatus(newStatus, current.driverId);

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
              driverId: current.driverId,
            );
          }
        }
      },
    );
  }

  Future<void> acceptOrder(OrderModel order) async {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;

      final result = await orderRepository.acceptOrder(order.id);
      result.fold(
        (error) => null,
        (success) {
          final updatedOrder = order.copyWith(
            status: OrderStatus.accepted,
            driverId: current.driverId,
            driverName: current.driverName,
            driverPhone: current.driverPhone,
          );

          socketService.joinOrderRoom(order.id);
          final updatedAvailable =
              current.availableOrders.where((o) => o.id != order.id).toList();

          emit(current.copyWith(
            availableOrders: updatedAvailable,
            activeOrder: updatedOrder,
          ));
        },
      );
    }
  }

  Future<void> recordReceiptAndMoveToDelivery({
    required double actualReceiptCost,
    String? receiptNote,
  }) async {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      if (current.activeOrder == null) return;

      final orderId = current.activeOrder!.id;
      final result = await orderRepository.updateOrderStatus(
        orderId: orderId,
        status: OrderStatus.pickedUp,
        actualReceiptCost: actualReceiptCost,
        receiptNote: receiptNote,
      );

      result.fold(
        (error) => null,
        (success) {
          final updatedOrder = current.activeOrder!.copyWith(
            status: OrderStatus.pickedUp,
            actualReceiptCost: actualReceiptCost,
            receiptNote: receiptNote,
          );
          emit(current.copyWith(activeOrder: updatedOrder));
        },
      );
    }
  }

  Future<void> updateOrderStatus(OrderStatus newStatus) async {
    if (state is DriverReadyState) {
      final current = state as DriverReadyState;
      if (current.activeOrder == null) return;

      final orderId = current.activeOrder!.id;
      final result = await orderRepository.updateOrderStatus(
        orderId: orderId,
        status: newStatus,
      );

      result.fold(
        (error) => null,
        (success) {
          if (newStatus == OrderStatus.delivered) {
            final feeEarned =
                current.activeOrder!.deliveryFee + current.activeOrder!.tip;
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
        },
      );
    }
  }
}
