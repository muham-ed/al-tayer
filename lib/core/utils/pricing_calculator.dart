import 'package:geolocator/geolocator.dart';

class PricingResult {
  final double distanceKm;
  final double baseFee;
  final double distanceFee;
  final double tipFee;
  final double totalDeliveryFee;

  const PricingResult({
    required this.distanceKm,
    required this.baseFee,
    required this.distanceFee,
    required this.tipFee,
    required this.totalDeliveryFee,
  });
}

class PricingCalculator {
  // قواعد تسعير العجمي والبيطاش الواقعية
  static const double baseFare = 15.0; // فتحة العداد لأول 1.5 كم
  static const double includedDistanceKm = 1.5;
  static const double perKmRate = 4.5; // جنيه لكل كم إضافي
  static const double minimumDeliveryFee = 18.0;

  /// حساب المسافة بالكيلومتر بين نقطتين إحداثيات
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    // نضرب في 1.25 كمعامل لشوارع العجمي والملفات الواقعية (Winding factor)
    return (distanceInMeters / 1000.0) * 1.25;
  }

  /// حساب تكلفة التوصيل الديناميكية بناءً على المسافة والإكرامية
  static PricingResult calculateFee({
    required double distanceKm,
    double tip = 0.0,
  }) {
    double distanceFee = 0.0;
    if (distanceKm > includedDistanceKm) {
      final extraKm = distanceKm - includedDistanceKm;
      distanceFee = extraKm * perKmRate;
    }

    double total = baseFare + distanceFee + tip;
    if (total < minimumDeliveryFee) {
      total = minimumDeliveryFee;
    }

    // تقريب لأقرب 5 جنيهات لتسهيل التعامل الكاش مع المناديب (لا فكة نص جنيه وجنيه)
    final roundedTotal = (total / 5.0).ceil() * 5.0;

    return PricingResult(
      distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
      baseFee: baseFare,
      distanceFee: double.parse(distanceFee.toStringAsFixed(1)),
      tipFee: tip,
      totalDeliveryFee: roundedTotal,
    );
  }
}
