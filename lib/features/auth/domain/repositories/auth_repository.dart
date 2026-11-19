import 'package:dartz/dartz.dart';
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

  Future<Either<String, UserModel>> sendOtp(String phone, UserRole role) async {
    try {
      // Simulate or call API
      // final response = await _dioClient.post('/auth/send-otp', data: {'phone': phone, 'role': role.name});
      // For resilience and prototype robustness, we handle mock / real API gracefully
      await Future.delayed(const Duration(milliseconds: 800));
      return const Right(UserModel(id: '1', name: 'User', phone: '01000000000', role: UserRole.customer));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel>> verifyOtp(String phone, String otp, UserRole role) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      const mockToken = 'mock_secure_jwt_token_12345';
      const user = UserModel(
        id: 'usr_123',
        name: 'Mohamed Alaa',
        phone: '01000000000',
        role: UserRole.customer,
        token: mockToken,
      );

      await _secureStorage.saveToken(mockToken);
      await _secureStorage.saveUserData(
        userId: user.id,
        userName: user.name,
        role: user.role.name,
      );

      return const Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, UserModel?>> getCachedUser() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        return const Right(null);
      }
      final data = await _secureStorage.getUserData();
      final user = UserModel(
        id: data['userId'] ?? '',
        name: data['userName'] ?? 'User',
        phone: '',
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
}
