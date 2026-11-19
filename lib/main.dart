import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/driver/presentation/cubit/driver_cubit.dart';
import 'features/order/presentation/cubit/order_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const AlTayerApp());
}

class AlTayerApp extends StatelessWidget {
  const AlTayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()..checkAuthStatus()),
        BlocProvider<OrderCubit>(create: (_) => di.sl<OrderCubit>()),
        BlocProvider<DriverCubit>(create: (_) => di.sl<DriverCubit>()),
      ],
      child: MaterialApp(
        title: 'ع الطاير - Al Tayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomePage(),
      ),
    );
  }
}
