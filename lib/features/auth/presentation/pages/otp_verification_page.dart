import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/models/user_model.dart';
import '../cubit/auth_cubit.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  final UserRole role;
  final String? name;

  const OtpVerificationPage({
    super.key,
    required this.phone,
    required this.role,
    this.name,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController(text: '1234');

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تأكيد رقم الهاتف'),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticatedState) {
            // تم تسجيل الدخول بنجاح - الخروج من شاشات الـ Auth والعودة لـ Main Flow
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'أدخل كود التحقق المرسل إلى\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'كود تجريبي: 1234',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _otpController,
                  labelText: 'كود التحقق (4 أرقام) *',
                  hintText: '----',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'تأكيد ودخول التطبيق',
                  isLoading: isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    final otp = _otpController.text.trim();
                    if (otp.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('برجاء كتابة الكود')),
                      );
                      return;
                    }
                    context.read<AuthCubit>().verifyOtp(
                          phone: widget.phone,
                          otp: otp,
                          role: widget.role,
                          name: widget.name,
                        );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
