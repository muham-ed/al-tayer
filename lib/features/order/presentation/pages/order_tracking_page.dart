import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/launcher_helper.dart';
import '../../domain/models/order_model.dart';
import '../cubit/order_cubit.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة الطلب في الوقت الفعلي'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderTrackingState) {
            final order = state.order;

            return Column(
              children: [
                // Live OpenStreetMap Layer
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            state.driverLat ?? order.dropoffLocation.latitude,
                            state.driverLng ?? order.dropoffLocation.longitude,
                          ),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.altayer.al_tayer',
                          ),
                          MarkerLayer(
                            markers: [
                              // Dropoff Destination Marker
                              Marker(
                                point: LatLng(
                                  order.dropoffLocation.latitude,
                                  order.dropoffLocation.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.error,
                                  size: 38,
                                ),
                              ),
                              // Pickup Location Marker (if available)
                              if (order.pickupLocation != null)
                                Marker(
                                  point: LatLng(
                                    order.pickupLocation!.latitude,
                                    order.pickupLocation!.longitude,
                                  ),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.info,
                                    size: 32,
                                  ),
                                ),
                              // Live Moving Driver Marker
                              if (state.driverLat != null && state.driverLng != null)
                                Marker(
                                  point: LatLng(state.driverLat!, state.driverLng!),
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.motorcycle_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'تتبع مباشر (OpenStreetMap)',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Order Status & Accounting Bottom Sheet
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'رقم الطلب: ${order.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'المسافة: ~${order.distanceKm} كم | كاش عند الاستلام',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              _buildStatusBadge(order.status),
                            ],
                          ),
                          const Divider(height: 24),

                          // Real-time Driver Contact Card with Direct Call & WhatsApp
                          if (order.driverName != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.two_wheeler_rounded, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.driverName!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          order.driverPhone ?? '',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
                                    onPressed: () {
                                      if (order.driverPhone != null) {
                                        LauncherHelper.makePhoneCall(order.driverPhone!);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                                    onPressed: () {
                                      if (order.driverPhone != null) {
                                        LauncherHelper.openWhatsApp(phone: order.driverPhone!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Verified Receipt / Bill Details (منع الاحتيال)
                          if (order.actualReceiptCost > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'تم تسجيل فاتورة الشراء بواسطة المندوب:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'قيمة المشتريات الفعلية: ${order.actualReceiptCost.toInt()} ج.م',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (order.receiptNote != null)
                                    Text('ملاحظة: ${order.receiptNote!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Summary Calculation
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المبلغ الإجمالي المستحق كاش:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  '${order.totalOrderDue.toInt()} ج.م',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dropoff details with landmark
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.dropoffLocation.address,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (order.dropoffLocation.landmark != null)
                                      Text(
                                        'علامة مميزة: ${order.dropoffLocation.landmark!}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    if (order.dropoffLocation.buildingDetails != null)
                                      Text(
                                        'العمارة: ${order.dropoffLocation.buildingDetails!}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    String text;
    Color color;

    switch (status) {
      case OrderStatus.pending:
        text = 'جاري البحث عن كابتن';
        color = AppColors.warning;
        break;
      case OrderStatus.accepted:
        text = 'تم القبول';
        color = AppColors.info;
        break;
      case OrderStatus.atStore:
        text = 'في المحل للشراء';
        color = AppColors.primary;
        break;
      case OrderStatus.pickedUp:
        text = 'في الطريق إليك';
        color = AppColors.accent;
        break;
      case OrderStatus.delivered:
        text = 'تم التوصيل';
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
        text = 'ملغي';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
