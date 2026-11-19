import 'package:dartz/dartz.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final DioClient _dioClient;

  OrderRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<Either<String, OrderModel>> createOrder(OrderModel order) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      return Right(order);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<OrderModel>>> getAvailableOrders() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return const Right([]);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
