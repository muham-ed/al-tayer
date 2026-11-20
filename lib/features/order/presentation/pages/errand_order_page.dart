import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/services/location_service.dart';
import '../../../../injection_container.dart';
import '../cubit/order_cubit.dart';
import 'order_tracking_page.dart';

class ErrandOrderPage extends StatefulWidget {
  const ErrandOrderPage({super.key});

  @override
  State<ErrandOrderPage> createState() => _ErrandOrderPageState();
}

class _ErrandOrderPageState extends State<ErrandOrderPage> {
  final _itemsController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController(text: 'البيطاش - شارع الحنفية');
  final _landmarkController = TextEditingController();
  final _buildingController = TextEditingController();
  final _costController = TextEditingController();

  double _estimatedDistanceKm = 2.5;
  double _tipAmount = 0.0;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationForDropoff();
  }

  Future<void> _fetchCurrentLocationForDropoff() async {
    setState(() => _isLocating = true);
    try {
      final pos = await sl<LocationService>().getCurrentPosition();
      if (pos != null && mounted) {
        // إذا توفر الموقع، نحسب المسافة الحقيقية بين موقع المستخدم الحالي وأقرب سنتر تجاري في البيطاش
        // نقطة مركز البيطاش: (31.1180, 29.7820)
        final realDistance = PricingCalculator.calculateDistanceKm(
          startLat: 31.1180,
          startLng: 29.7820,
          endLat: pos.latitude,
          endLng: pos.longitude,
        );
        setState(() {
          _estimatedDistanceKm = realDistance < 1.0 ? 1.5 : realDistance;
        });
      }
    } catch (_) {
      // الاستمرار بالقيمة الافتراضية بأمان
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _landmarkController.dispose();
    _buildingController.dispose();
    _costController.dispose();
    super.dispose();
  }

  PricingResult get _currentPricing {
    return PricingCalculator.calculateFee(
      distanceKm: _estimatedDistanceKm,
      tip: _tipAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricing = _currentPricing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب مشوار (هاتلي أي حاجة)'),
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreatedSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrderTrackingPage()),
            );
          } else if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is OrderLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box with Fraud Warning
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نظام ع الطاير المحمي: الحد الأقصى للمشتريات كاش 300 ج.م، ويتم مراجعة الفاتورة مع المندوب عند الاستلام.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Details
                CustomTextField(
                  controller: _itemsController,
                  labelText: 'تفاصيل طلبك أو المشتريات بدقة *',
                  hintText: 'مثال: 1 كيلو جبنة رومي قديمة من فتح الله + علبة لبن...',
                  maxLines: 3,
                  prefixIcon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 16),

                // Pickup location
                CustomTextField(
                  controller: _pickupController,
                  labelText: 'مكان الشراء أو المحل (اختياري)',
                  hintText: 'مثال: سوبرماركت فلان بجوار مسجد الصالحين',
                  prefixIcon: Icons.storefront_rounded,
                  onChanged: (val) {
                    setState(() {
                      // لو حدد مكان شراء بعيد نزود المسافة التقديرية تلقائياً
                      _estimatedDistanceKm = val.trim().isNotEmpty ? 4.0 : 2.0;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Dropoff location
                CustomTextField(
                  controller: _dropoffController,
                  labelText: 'مكان التوصيل (الشارع والمنطقة) *',
                  hintText: 'البيطاش - شارع الحنفية',
                  prefixIcon: _isLocating ? Icons.my_location : Icons.location_on_rounded,
                ),
                const SizedBox(height: 14),

                // Alexandria Mandatory Landmark (العلامة المميزة الإجبارية)
                CustomTextField(
                  controller: _landmarkController,
                  labelText: 'علامة مميزة قريبة جداً (إجباري في شوارع العجمي) *',
                  hintText: 'مثال: أمام كافيه كذا / ناصية صيدلية د. فلان',
                  prefixIcon: Icons.flag_rounded,
                ),
                const SizedBox(height: 14),

                // Building & Floor
                CustomTextField(
                  controller: _buildingController,
                  labelText: 'رقم العمارة والدور والشقة',
                  hintText: 'عمارة 12، الدور 4، شقة 8',
                  prefixIcon: Icons.apartment_rounded,
                ),
                const SizedBox(height: 16),

                // Estimated Budget with Fraud Warning
                CustomTextField(
                  controller: _costController,
                  labelText: 'المبلغ التقديري للشراء (بحد أقصى 300 ج.م)',
                  hintText: 'مثال: 120',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_rounded,
                ),
                const SizedBox(height: 20),

                // Tip / Expedited Delivery (إكرامية لسرعة القبول في الزحمة أو الليل)
                const Text(
                  'سرّع وصول مشوارك (إكرامية للمندوب في الزحمة):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [0.0, 5.0, 10.0, 15.0].map((tip) {
                    final isSelected = _tipAmount == tip;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(tip == 0.0 ? 'بدون' : '+${tip.toInt()}ج'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _tipAmount = tip),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Dynamic Pricing Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المسافة التقديرية للمشوار:',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            '~ ${pricing.distanceKm} كم',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تكلفة التوصيل الأساسية:',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            '${pricing.totalDeliveryFee.toInt()} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (_tipAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إكرامية تشجيعية للكابتن:',
                              style: TextStyle(fontSize: 12, color: AppColors.success),
                            ),
                            Text(
                              '+${_tipAmount.toInt()} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'تأكيد الطلب (${pricing.totalDeliveryFee.toInt()} ج.م توصيل)',
                  isLoading: isLoading,
                  icon: Icons.delivery_dining_rounded,
                  onPressed: () {
                    if (_itemsController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('برجاء كتابة تفاصيل طلبك أولاً')),
                      );
                      return;
                    }
                    if (_landmarkController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('برجاء كتابة علامة مميزة لتفادي ضياع المندوب في العجمي')),
                      );
                      return;
                    }

                    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
                    if (cost > 300.0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الحد الأقصى للمشتريات كاش في المشوار الواحد هو 300 ج.م لحماية المندوب')),
                      );
                      return;
                    }

                    context.read<OrderCubit>().createErrandOrder(
                          itemsDescription: _itemsController.text.trim(),
                          dropoffAddress: _dropoffController.text.trim(),
                          landmark: _landmarkController.text.trim(),
                          buildingDetails: _buildingController.text.trim(),
                          pickupAddress: _pickupController.text.trim(),
                          estimatedCost: cost,
                          tip: _tipAmount,
                          simulatedDistanceKm: _estimatedDistanceKm,
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
