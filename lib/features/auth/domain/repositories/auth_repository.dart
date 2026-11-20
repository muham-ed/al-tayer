import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  AuthRepository({
    required DioClient dioClient,
    required SecureStorageService secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage;

  /// إرسال OTP للسيرفر الحقيقي
  Future<Either<String, bool>> sendOtp(String phone, UserRole role) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/send-otp',
        data: {'phone': phone, 'role': role.name},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // في وضع التطوير، السيرفر بيرجع الـ OTP في الـ response
        final devOtp = response.data['devOtp'];
        if (devOtp != null) {
          // ignore: avoid_print
          print('🔑 [DEV] OTP: $devOtp');
        }
        return const Right(true);
      }

      return Left(response.data['error'] ?? 'فشل إرسال الكود');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  /// التحقق من OTP والحصول على JWT
  Future<Either<String, UserModel>> verifyOtp(
      String phone, String otp, UserRole role) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp, 'role': role.name},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userData = response.data['user'] as Map<String, dynamic>;

        final user = UserModel.fromJson({...userData, 'token': token});

        // حفظ في Secure Storage
        await _secureStorage.saveToken(token);
        await _secureStorage.saveUserData(
          userId: user.id,
          userName: user.name,
          role: user.role.name,
          phone: user.phone,
        );

        return Right(user);
      }

      return Left(response.data['error'] ?? 'فشل التحقق');
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'];
      return Left(serverError ?? _mapDioError(e));
    } catch (e) {
      return Left('خطأ غير متوقع: $e');
    }
  }

  /// استرجاع بيانات المستخدم المحفوظة
  Future<Either<String, UserModel?>> getCachedUser() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        return const Right(null);
      }

      final data = await _secureStorage.getUserData();
      if (data['userId'] == null || data['userId']!.isEmpty) {
        return const Right(null);
      }

      final user = UserModel(
        id: data['userId']!,
        name: data['userName'] ?? 'مستخدم',
        phone: data['phone'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == data['role'],
          orElse: () => UserRole.customer,
        ),
        token: token,
      );

      return Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'السيرفر بطيء، حاول تاني';
      case DioExceptionType.connectionError:
        return 'مفيش إنترنت أو السيرفر مش شغال';
      default:
        return 'خطأ في الاتصال بالسيرفر';
    }
  }
}
