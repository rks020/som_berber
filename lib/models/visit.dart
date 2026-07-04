class Visit {
  final String id;
  final String customerId;
  final String
  customerName; // Stores customer name at the time of visit (handles quick/unregistered customers too)
  final String barberId;
  final List<String> serviceIds;
  final List<String> serviceNames; // Historical snapshot of service names
  final List<double>
  servicePrices; // Historical snapshot of prices at that moment
  final double totalPrice;
  final String paymentMethod; // "Nakit", "Kart", "Veresiye"
  final DateTime dateTime;
  final String notes;
  final String status; // "Tamamlandı", "Randevu"
  final String? photoPath;

  Visit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.barberId,
    required this.serviceIds,
    required this.serviceNames,
    required this.servicePrices,
    required this.totalPrice,
    required this.paymentMethod,
    required this.dateTime,
    this.notes = '',
    this.status = 'Tamamlandı',
    this.photoPath,
  });

  Visit copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? barberId,
    List<String>? serviceIds,
    List<String>? serviceNames,
    List<double>? servicePrices,
    double? totalPrice,
    String? paymentMethod,
    DateTime? dateTime,
    String? notes,
    String? status,
    String? photoPath,
  }) {
    return Visit(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      barberId: barberId ?? this.barberId,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      servicePrices: servicePrices ?? this.servicePrices,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId.isNotEmpty ? customerId : null,
      'barber_id': barberId.isNotEmpty ? barberId : null,
      'date_time': dateTime.toUtc().toIso8601String(),
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'photo_path': photoPath,
      'status': status,
      'services': serviceNames, // stored as jsonb array of strings in DB
    };
  }

  factory Visit.fromMap(Map<dynamic, dynamic> map) {
    return Visit(
      id: map['id'] as String,
      customerId: (map['customer_id'] ?? '') as String,
      customerName: '', // Lookup dynamically if needed
      barberId: (map['barber_id'] ?? '') as String,
      serviceIds: const [],
      serviceNames: map['services'] != null ? List<String>.from(map['services'] as List) : const [],
      servicePrices: const [],
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['payment_method'] ?? '') as String,
      dateTime: DateTime.parse(map['date_time'] as String).toLocal(),
      notes: '',
      status: (map['status'] ?? 'Tamamlandı') as String,
      photoPath: map['photo_path'] as String?,
    );
  }
}
