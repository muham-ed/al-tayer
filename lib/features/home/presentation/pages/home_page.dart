import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../driver/presentation/pages/driver_dashboard_page.dart';
import '../../../order/presentation/pages/errand_order_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticatedState ? authState.user : null;
        final isDriver = user?.role == UserRole.driver;

        // إذا كان الحساب مندوب/كابتن، يفتح مباشرة لوحة تحكم الكابتن
        if (isDriver) {
          return const DriverDashboardPage();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              children: const [
                Text(
                  AppStrings.appName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                ),
                Text(
                  AppStrings.defaultArea,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(
                user != null ? Icons.person_rounded : Icons.login_rounded,
                color: AppColors.primary,
              ),
              onPressed: () {
                if (user == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                } else {
                  _showProfileSheet(context, user);
                }
              },
            ),
            actions: [
              // زر تبديل سريع لوضع المندوب (Driver Mode Toggle)
              TextButton.icon(
                icon: const Icon(Icons.two_wheeler_rounded, size: 18, color: AppColors.secondary),
                label: const Text(
                  'وضع الكابتن',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverDashboardPage()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Greeting if logged in
                if (user != null) ...[
                  Text(
                    'أهلاً بك يا ${user.name} 👋',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                ],

                // Hero Banner: "هاتلي أي حاجة" (Main Service)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ErrandOrderPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'خدمة "هاتلي أي حاجة"',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'اطلب أي مشوار أو غرض من أي مكان في العجمي والبيطاش والمندوب يوصلهولك فوراً!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'اطلب الآن',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Category Sections
                const Text(
                  'أقسام التوصيل السريع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  children: [
                    _buildCategoryCard(
                      title: 'سوبرماركت وبقالة',
                      icon: Icons.shopping_basket_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ErrandOrderPage()),
                        );
                      },
                    ),
                    _buildCategoryCard(
                      title: 'صيدلية وعلاج',
                      icon: Icons.local_pharmacy_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ErrandOrderPage()),
                        );
                      },
                    ),
                    _buildCategoryCard(
                      title: 'خضار وفاكهة',
                      icon: Icons.eco_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ErrandOrderPage()),
                        );
                      },
                    ),
                    _buildCategoryCard(
                      title: 'مطاعم وأكلات',
                      icon: Icons.restaurant_rounded,
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ErrandOrderPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.phone,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () {
                  context.read<AuthCubit>().logout();
                  Navigator.pop(bottomSheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
