import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

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
  final OrderRepository orderRepository;
  final SecureStorageService secureStorage;

  OrderCubit({
    required this.socketService,
    required this.orderRepository,
    required this.secureStorage,
  }) : super(OrderInitial());

  void createErrandOrder({
    required String itemsDescription,
    required String dropoffAddress,
    required String landmark,
    String? buildingDetails,
    String? pickupAddress,
    double estimatedCost = 0.0,
    double tip = 0.0,
    double simulatedDistanceKm = 2.5,
  }) async {
    emit(OrderLoading());
    try {
      final userData = await secureStorage.getUserData();
      final customerId = userData['userId'] ?? 'CUST-TEMP';
      final customerName = userData['userName'] ?? 'عميل ع الطاير';
      final customerPhone = userData['phone'] ?? '';

      final pricing = PricingCalculator.calculateFee(
        distanceKm: simulatedDistanceKm,
        tip: tip,
      );

      final initialOrder = OrderModel(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
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

      // إنشاء الطلب عبر السيرفر الحقيقي
      final result = await orderRepository.createOrder(initialOrder);

      result.fold(
        (error) => emit(OrderFailure('فشل في إرسال الطلب: $error')),
        (createdOrder) {
          // الانضمام لغرفة الطلب في السوكيت لمتابعة المندوب
          socketService.joinOrderRoom(createdOrder.id);
          emit(OrderCreatedSuccess(createdOrder));
          startTracking(createdOrder);
        },
      );
    } catch (e) {
      emit(OrderFailure('فشل في إرسال الطلب: $e'));
    }
  }

  void startTracking(OrderModel order) {
    emit(OrderTrackingState(order: order));

    // الاستماع لموقع المندوب المباشر
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

    // الاستماع لتغييرات حالة الطلب والفاتورة الفعلية
    socketService.onOrderStatusChange((newStatus, extra) {
      if (state is OrderTrackingState) {
        final current = state as OrderTrackingState;
        final updatedStatus = OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == newStatus.toLowerCase(),
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
