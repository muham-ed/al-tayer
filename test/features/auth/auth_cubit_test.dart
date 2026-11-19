import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:al_tayer/features/auth/domain/models/user_model.dart';
import 'package:al_tayer/features/auth/domain/repositories/auth_repository.dart';
import 'package:al_tayer/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:al_tayer/core/network/dio_client.dart';
import 'package:al_tayer/core/services/secure_storage_service.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  DioClient get _dioClient => throw UnimplementedError();

  @override
  SecureStorageService get _secureStorage => throw UnimplementedError();

  @override
  Future<Either<String, UserModel>> sendOtp(String phone, UserRole role) async {
    return const Right(UserModel(id: '1', name: 'User', phone: '01000000000', role: UserRole.customer));
  }

  @override
  Future<Either<String, UserModel>> verifyOtp(String phone, String otp, UserRole role) async {
    return const Right(UserModel(
      id: 'usr_123',
      name: 'Mohamed Alaa',
      phone: '01000000000',
      role: UserRole.customer,
      token: 'mock_token',
    ));
  }

  @override
  Future<Either<String, UserModel?>> getCachedUser() async {
    return const Right(null);
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('AuthCubit Tests', () {
    late FakeAuthRepository fakeAuthRepository;
    late AuthCubit authCubit;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      authCubit = AuthCubit(authRepository: fakeAuthRepository);
    });

    tearDown(() {
      authCubit.close();
    });

    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(AuthInitial()));
    });

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthOtpSentState] when sendOtp succeeds',
      build: () => authCubit,
      act: (cubit) => cubit.sendOtp(phone: '01012345678', role: UserRole.customer),
      expect: () => [
        AuthLoading(),
        const AuthOtpSentState(phone: '01012345678', role: UserRole.customer),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthFailureState] when verifyOtp gets invalid otp length',
      build: () => authCubit,
      act: (cubit) => cubit.verifyOtp(phone: '01012345678', otp: '12', role: UserRole.customer),
      expect: () => [
        AuthLoading(),
        const AuthFailureState('رمز التحقق غير صحيح، برجاء إدخال 4 أرقام'),
      ],
    );
  });
}
