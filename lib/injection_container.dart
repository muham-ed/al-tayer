import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'core/services/location_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/socket_service.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/driver/presentation/cubit/driver_cubit.dart';
import 'features/order/domain/repositories/order_repository.dart';
import 'features/order/presentation/cubit/order_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Services & Network
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  final socketService = SocketService();
  await socketService.init();
  sl.registerLazySingleton<SocketService>(() => socketService);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(
        dioClient: sl(),
        secureStorage: sl(),
      ));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepository(
        dioClient: sl(),
      ));

  // Cubits / Blocs
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository: sl()));
  sl.registerFactory<OrderCubit>(() => OrderCubit(socketService: sl()));
  sl.registerFactory<DriverCubit>(() => DriverCubit(
        socketService: sl(),
        locationService: sl(),
      ));
}
