enum OrderStatus {
  pending,       // بانتظار مندوب
  accepted,      // وافق المندوب
  atStore,       // المندوب في المحل
  pickedUp,      // استلم الطلب وسجل الفاتورة
  delivered,     // تم التوصيل واستلام الكاش
  cancelled      // ملغي
}

enum OrderType {
  errand,     // هاتلي أي حاجة (مشوار حر)
  grocery,    // سوبرماركت وبقالة
  pharmacy,   // صيدلية
  vegetables  // خضار وفاكهة
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;        // علامة مميزة (إجباري في شوارع العجمي)
  final String? buildingDetails; // رقم العمارة والدور والشقة

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.buildingDetails,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'landmark': landmark,
    'buildingDetails': buildingDetails,
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: ((json['latitude'] ?? 31.1200) as num).toDouble(),
    longitude: ((json['longitude'] ?? 29.7800) as num).toDouble(),
    address: json['address'] as String? ?? '',
    landmark: json['landmark'] as String?,
    buildingDetails: json['buildingDetails'] as String?,
  );
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final OrderType type;
  final OrderStatus status;
  final String itemsDescription;
  final LocationPoint? pickupLocation;
  final LocationPoint dropoffLocation;
  final double distanceKm;
  final double deliveryFee;
  final double estimatedCost;
  final double actualReceiptCost; // سعر الفاتورة الفعلي بعد الشراء
  final String? receiptNote;      // ملاحظات الفاتورة من الكابتن
  final double tip;               // إكرامية إضافية للمندوب
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.type,
    required this.status,
    required this.itemsDescription,
    this.pickupLocation,
    required this.dropoffLocation,
    this.distanceKm = 2.0,
    required this.deliveryFee,
    this.estimatedCost = 0.0,
    this.actualReceiptCost = 0.0,
    this.receiptNote,
    this.tip = 0.0,
    required this.createdAt,
  });

  double get totalOrderDue {
    // المبلغ الإجمالي المطلوب من العميل: (توصيل + فاتورة فعلية أو تقديرية + إكرامية)
    final itemsCost = actualReceiptCost > 0 ? actualReceiptCost : estimatedCost;
    return itemsCost + deliveryFee + tip;
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    String? driverName,
    String? driverPhone,
    OrderType? type,
    OrderStatus? status,
    String? itemsDescription,
    LocationPoint? pickupLocation,
    LocationPoint? dropoffLocation,
    double? distanceKm,
    double? deliveryFee,
    double? estimatedCost,
    double? actualReceiptCost,
    String? receiptNote,
    double? tip,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      type: type ?? this.type,
      status: status ?? this.status,
      itemsDescription: itemsDescription ?? this.itemsDescription,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualReceiptCost: actualReceiptCost ?? this.actualReceiptCost,
      receiptNote: receiptNote ?? this.receiptNote,
      tip: tip ?? this.tip,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'type': type.name,
    'status': status.name,
    'itemsDescription': itemsDescription,
    'pickupLocation': pickupLocation?.toJson(),
    'dropoffLocation': dropoffLocation.toJson(),
    'distanceKm': distanceKm,
    'deliveryFee': deliveryFee,
    'estimatedCost': estimatedCost,
    'actualReceiptCost': actualReceiptCost,
    'receiptNote': receiptNote,
    'tip': tip,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] ?? '',
    customerId: json['customerId'] ?? '',
    customerName: json['customerName'] ?? '',
    customerPhone: json['customerPhone'] ?? '',
    driverId: json['driverId'],
    driverName: json['driverName'],
    driverPhone: json['driverPhone'],
    type: OrderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OrderType.errand,
    ),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderStatus.pending,
    ),
    itemsDescription: json['itemsDescription'] ?? '',
    pickupLocation: json['pickupLocation'] != null
        ? LocationPoint.fromJson(json['pickupLocation'])
        : null,
    dropoffLocation: LocationPoint.fromJson(json['dropoffLocation'] ?? {}),
    distanceKm: ((json['distanceKm'] ?? 2.0) as num).toDouble(),
    deliveryFee: ((json['deliveryFee'] ?? 20.0) as num).toDouble(),
    estimatedCost: ((json['estimatedCost'] ?? 0.0) as num).toDouble(),
    actualReceiptCost: ((json['actualReceiptCost'] ?? 0.0) as num).toDouble(),
    receiptNote: json['receiptNote'],
    tip: ((json['tip'] ?? 0.0) as num).toDouble(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}
