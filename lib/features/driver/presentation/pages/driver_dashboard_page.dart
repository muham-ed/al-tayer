import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/launcher_helper.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../order/domain/models/order_model.dart';
import '../cubit/driver_cubit.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة تحكم الكابتن - ع الطاير'),
      ),
      body: BlocBuilder<DriverCubit, DriverState>(
        builder: (context, state) {
          if (state is DriverReadyState) {
            return Column(
              children: [
                // Driver Status & Daily Earnings Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: state.isOnline ? AppColors.success : AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.isOnline ? 'متصل ومتاح للطلبات' : 'أنت غير متصل',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أرباح اليوم: ${state.todayEarnings.toInt()} ج.م',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: state.isOnline,
                        activeThumbColor: AppColors.success,
                        onChanged: (_) {
                          context.read<DriverCubit>().toggleOnlineStatus('DRV-1');
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: state.activeOrder != null
                      ? _ActiveOrderView(order: state.activeOrder!)
                      : _buildAvailableOrdersList(context, state.availableOrders, state.isOnline),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAvailableOrdersList(BuildContext context, List<OrderModel> orders, bool isOnline) {
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'أنت غير متصل حالياً\nفعّل الاتصال بالأعلى لبدء استقبال مشاوير وطلبات',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات جديدة حالياً في منطقتك..'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'مشوار: ~${order.distanceKm} كم',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${(order.deliveryFee + order.tip).toInt()} ج.م صافي ليك',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  order.itemsDescription,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Addresses + Landmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.dropoffLocation.address} (${order.dropoffLocation.landmark ?? "بدون علامة"})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: 'قبول المشوار ع الطاير',
                  icon: Icons.check,
                  onPressed: () {
                    context.read<DriverCubit>().acceptOrder(order);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveOrderView extends StatefulWidget {
  final OrderModel order;
  const _ActiveOrderView({required this.order});

  @override
  State<_ActiveOrderView> createState() => _ActiveOrderViewState();
}

class _ActiveOrderViewState extends State<_ActiveOrderView> {
  final _receiptCostController = TextEditingController();
  final _receiptNoteController = TextEditingController();

  @override
  void dispose() {
    _receiptCostController.dispose();
    _receiptNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المشوار النشط حالياً',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'أجرتك: ${(order.deliveryFee + order.tip).toInt()} ج.م',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Customer info & Contact actions
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            order.customerPhone,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
                      onPressed: () => LauncherHelper.makePhoneCall(order.customerPhone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                      onPressed: () => LauncherHelper.openWhatsApp(phone: order.customerPhone),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('المطلوب شراؤه / إحضاره:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(order.itemsDescription, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),

                // Landmark & Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عنوان العميل: ${order.dropoffLocation.address}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🚩 العلامة المميزة: ${order.dropoffLocation.landmark ?? "غير محددة"}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (order.dropoffLocation.buildingDetails != null)
                        Text(
                          '🏢 العمارة / الدور: ${order.dropoffLocation.buildingDetails!}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lifecycle Progression Controls
          const Text('تحديث حالة المشوار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          if (order.status == OrderStatus.accepted)
            CustomButton(
              text: 'وصلت لمكان الشراء / المحل',
              backgroundColor: AppColors.info,
              icon: Icons.storefront_rounded,
              onPressed: () {
                context.read<DriverCubit>().updateOrderStatus(OrderStatus.atStore);
              },
            ),

          if (order.status == OrderStatus.atStore) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تسجيل فاتورة الشراء الفعلية (حماية حقك وحق العميل):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _receiptCostController,
                    labelText: 'سعر الفاتورة الفعلي من المحل (ج.م) *',
                    hintText: 'مثال: 95',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _receiptNoteController,
                    labelText: 'ملاحظة على الفاتورة (اختياري)',
                    hintText: 'مثال: تم شراء حجم كبير بدل صغير لعدم التوفر',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: 'تأكيد الشراء والتحرك للعميل',
              backgroundColor: AppColors.accent,
              icon: Icons.motorcycle_rounded,
              onPressed: () {
                final cost = double.tryParse(_receiptCostController.text.trim()) ?? 0.0;
                if (cost <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برجاء كتابة مبلغ الفاتورة الفعلي قبل التحرك')),
                  );
                  return;
                }
                context.read<DriverCubit>().recordReceiptAndMoveToDelivery(
                      actualReceiptCost: cost,
                      receiptNote: _receiptNoteController.text.trim(),
                    );
              },
            ),
          ],

          if (order.status == OrderStatus.pickedUp) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المطلوب تحصيله كاش من يد العميل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '${order.totalOrderDue.toInt()} ج.م',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: 'تم تسليم الطلب وتحصيل ${order.totalOrderDue.toInt()} ج.م كاش',
              backgroundColor: AppColors.success,
              icon: Icons.check_circle_rounded,
              onPressed: () {
                context.read<DriverCubit>().updateOrderStatus(OrderStatus.delivered);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('عاش يا كابتن! تم تحصيل المبلغ وإنهاء المشوار بنجاح')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
