import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../domain/models/order_model.dart';

// States
abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCreatedSuccess extends OrderState {
  final OrderModel order;
  const OrderCreatedSuccess(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderTrackingState extends OrderState {
  final OrderModel order;
  final double? driverLat;
  final double? driverLng;
  final double? driverBearing;

  const OrderTrackingState({
    required this.order,
    this.driverLat,
    this.driverLng,
    this.driverBearing,
  });

  OrderTrackingState copyWith({
    OrderModel? order,
    double? driverLat,
    double? driverLng,
    double? driverBearing,
  }) {
    return OrderTrackingState(
      order: order ?? this.order,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverBearing: driverBearing ?? this.driverBearing,
    );
  }

  @override
  List<Object?> get props => [order, driverLat, driverLng, driverBearing];
}

class OrderFailure extends OrderState {
  final String message;
  const OrderFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class OrderCubit extends Cubit<OrderState> {
  final SocketService socketService;

  OrderCubit({required this.socketService}) : super(OrderInitial());

  void createErrandOrder({
    required String itemsDescription,
    required String dropoffAddress,
    required String landmark,
    String? buildingDetails,
    String? pickupAddress,
    double estimatedCost = 0.0,
    double tip = 0.0,
    double simulatedDistanceKm = 2.5, // مسافة تقديرية بين المكانين
  }) async {
    emit(OrderLoading());
    try {
      // حساب التسعيرة الديناميكية الفعلية
      final pricing = PricingCalculator.calculateFee(
        distanceKm: simulatedDistanceKm,
        tip: tip,
      );

      final newOrder = OrderModel(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        customerId: 'CUST-101',
        customerName: 'محمد علاء',
        customerPhone: '01012345678',
        type: OrderType.errand,
        status: OrderStatus.pending,
        itemsDescription: itemsDescription,
        pickupLocation: pickupAddress != null && pickupAddress.isNotEmpty
            ? LocationPoint(latitude: 31.1167, longitude: 29.7833, address: pickupAddress)
            : null,
        dropoffLocation: LocationPoint(
          latitude: 31.1215,
          longitude: 29.7750,
          address: dropoffAddress,
          landmark: landmark,
          buildingDetails: buildingDetails,
        ),
        distanceKm: pricing.distanceKm,
        deliveryFee: pricing.totalDeliveryFee,
        estimatedCost: estimatedCost,
        tip: tip,
        createdAt: DateTime.now(),
      );

      // Join Order Room in Socket
      socketService.joinOrderRoom(newOrder.id);

      emit(OrderCreatedSuccess(newOrder));
      startTracking(newOrder);
    } catch (e) {
      emit(OrderFailure('فشل في إرسال الطلب: $e'));
    }
  }

  void startTracking(OrderModel order) {
    emit(OrderTrackingState(order: order));

    // Listen to real-time driver coordinates via WebSocket
    socketService.onLocationUpdate((lat, lng, bearing) {
      if (state is OrderTrackingState) {
        final current = state as OrderTrackingState;
        emit(current.copyWith(
          driverLat: lat,
          driverLng: lng,
          driverBearing: bearing,
        ));
      }
    });

    // Listen to Order Status Changes (including receipt updates from driver)
    socketService.onOrderStatusChange((newStatus, extra) {
      if (state is OrderTrackingState) {
        final current = state as OrderTrackingState;
        final updatedStatus = OrderStatus.values.firstWhere(
          (e) => e.name == newStatus,
          orElse: () => current.order.status,
        );

        final actualReceipt = extra['actualReceiptCost'] != null
            ? (extra['actualReceiptCost'] as num).toDouble()
            : current.order.actualReceiptCost;

        emit(current.copyWith(
          order: current.order.copyWith(
            status: updatedStatus,
            driverName: extra['driverName'] ?? current.order.driverName,
            driverPhone: extra['driverPhone'] ?? current.order.driverPhone,
            actualReceiptCost: actualReceipt,
            receiptNote: extra['receiptNote'] ?? current.order.receiptNote,
          ),
        ));
      }
    });
  }
}
