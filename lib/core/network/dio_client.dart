import 'package:dio/dio.dart';
import '../config/environment_config.dart';
import '../services/secure_storage_service.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService _secureStorage;

  DioClient({
    String? baseUrl,
    SecureStorageService? secureStorage,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? '${EnvironmentConfig.apiBaseUrl}/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }
}
