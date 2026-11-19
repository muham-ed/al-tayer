import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSentState extends AuthState {
  final String phone;
  final UserRole role;
  const AuthOtpSentState({required this.phone, required this.role});

  @override
  List<Object?> get props => [phone, role];
}

class AuthAuthenticatedState extends AuthState {
  final UserModel user;
  const AuthAuthenticatedState(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String error;
  const AuthFailureState(this.error);

  @override
  List<Object?> get props => [error];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial());

  Future<void> checkAuthStatus() async {
    final result = await _authRepository.getCachedUser();
    result.fold(
      (error) => emit(AuthUnauthenticatedState()),
      (user) {
        if (user != null && user.token != null) {
          emit(AuthAuthenticatedState(user));
        } else {
          emit(AuthUnauthenticatedState());
        }
      },
    );
  }

  void sendOtp({required String phone, required UserRole role}) async {
    emit(AuthLoading());
    final result = await _authRepository.sendOtp(phone, role);
    result.fold(
      (error) => emit(AuthFailureState(error)),
      (user) => emit(AuthOtpSentState(phone: phone, role: role)),
    );
  }

  void verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
    String? name,
  }) async {
    emit(AuthLoading());
    if (otp.length < 4) {
      emit(const AuthFailureState('رمز التحقق غير صحيح، برجاء إدخال 4 أرقام'));
      return;
    }

    final result = await _authRepository.verifyOtp(phone, otp, role);
    result.fold(
      (error) => emit(AuthFailureState(error)),
      (user) {
        final defaultName = role == UserRole.driver ? 'مندوب ع الطاير' : 'عميل ع الطاير';
        final finalName = (name != null && name.trim().isNotEmpty) ? name.trim() : defaultName;
        final updatedUser = user.copyWith(name: finalName, role: role, isOnline: role == UserRole.driver);
        emit(AuthAuthenticatedState(updatedUser));
      },
    );
  }

  void switchRole(UserRole newRole) async {
    if (state is AuthAuthenticatedState) {
      final current = (state as AuthAuthenticatedState).user;
      final updated = current.copyWith(role: newRole, isOnline: newRole == UserRole.driver);
      emit(AuthAuthenticatedState(updated));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthUnauthenticatedState());
  }
}
