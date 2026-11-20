import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DioClient _dioClient;

  OrderRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// إرسال طلب جديد للسيرفر
  Future<Either<String, OrderModel>> createOrder(OrderModel order) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders',
        data: {
          'customerId': order.customerId,
          'pickupLocation': order.pickupLocation?.toJson(),
          'dropoffLocation': order.dropoffLocation.toJson(),
          'price': order.deliveryFee,
          'itemsDescription': order.itemsDescription,
          'estimatedCost': order.estimatedCost,
          'tip': order.tip,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final serverOrder = response.data['order'];
        // دمج بيانات الطلب التي أنشأها السيرفر مع المعرف الرسمي
        return Right(order.copyWith(
          id: serverOrder['id'],
          createdAt: DateTime.tryParse(serverOrder['createdAt'] ?? '') ?? DateTime.now(),
        ));
      }

      return Left(response.data['error'] ?? 'فشل في إنشاء الطلب');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  /// جلب الطلبات المتاحة للمناديب من السيرفر
  Future<Either<String, List<OrderModel>>> getAvailableOrders() async {
    try {
      final response = await _dioClient.dio.get('/orders/available');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List ordersJson = response.data['orders'] ?? [];
        final orders = ordersJson.map((json) {
          // Prisma ترجع pickupLocation و dropoffLocation كسلاسل نصية JSON
          Map<String, dynamic> dropoff = {};
          Map<String, dynamic>? pickup;
          try {
            if (json['dropoffLocation'] is String) {
              // Parse if string
              dropoff = Map<String, dynamic>.from(
                Map.castFrom(json['dropoffLocation'] != null ? {} : {})
              );
            } else if (json['dropoffLocation'] is Map) {
              dropoff = Map<String, dynamic>.from(json['dropoffLocation']);
            }
          } catch (_) {}

          return OrderModel(
            id: json['id'],
            customerId: json['customerId'],
            customerName: json['customer']?['name'] ?? 'عميل ع الطاير',
            customerPhone: json['customer']?['phone'] ?? '',
            type: OrderType.errand,
            status: OrderStatus.pending,
            itemsDescription: json['itemsDescription'] ?? 'مشوار طلبات',
            pickupLocation: pickup != null ? LocationPoint.fromJson(pickup) : null,
            dropoffLocation: LocationPoint.fromJson(dropoff),
            deliveryFee: (json['price'] as num?)?.toDouble() ?? 20.0,
            estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
            tip: (json['tip'] as num?)?.toDouble() ?? 0.0,
            createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          );
        }).toList();

        return Right(orders);
      }

      return Left(response.data['error'] ?? 'فشل في جلب الطلبات');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  /// قبول طلب من قبل المندوب
  Future<Either<String, bool>> acceptOrder(String orderId) async {
    try {
      final response = await _dioClient.dio.patch('/orders/$orderId/accept');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return const Right(true);
      }
      return Left(response.data['error'] ?? 'فشل في قبول الطلب');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  /// تحديث حالة الطلب
  Future<Either<String, bool>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    double? actualReceiptCost,
    String? receiptNote,
  }) async {
    try {
      final statusMap = {
        OrderStatus.pending: 'PENDING',
        OrderStatus.accepted: 'ACCEPTED',
        OrderStatus.atStore: 'AT_STORE',
        OrderStatus.pickedUp: 'IN_TRANSIT',
        OrderStatus.delivered: 'DELIVERED',
        OrderStatus.cancelled: 'CANCELLED',
      };

      final response = await _dioClient.dio.patch(
        '/orders/$orderId/status',
        data: {
          'status': statusMap[status],
          if (actualReceiptCost != null) 'actualReceiptCost': actualReceiptCost,
          if (receiptNote != null) 'receiptNote': receiptNote,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return const Right(true);
      }
      return Left(response.data['error'] ?? 'فشل في تحديث حالة الطلب');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'السيرفر بطيء، حاول ثانية';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالسيرفر';
      default:
        return 'خطأ في الاتصال بالشبكة';
    }
  }
}
