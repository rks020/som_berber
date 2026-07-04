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
      'customerId': customerId,
      'customerName': customerName,
      'barberId': barberId,
      'serviceIds': serviceIds,
      'serviceNames': serviceNames,
      'servicePrices': servicePrices,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'status': status,
      'photoPath': photoPath,
    };
  }

  factory Visit.fromMap(Map<dynamic, dynamic> map) {
    return Visit(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String,
      barberId: map['barberId'] as String,
      serviceIds: List<String>.from(map['serviceIds'] as List),
      serviceNames: List<String>.from(map['serviceNames'] as List),
      servicePrices: (map['servicePrices'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      notes: (map['notes'] ?? '') as String,
      status: (map['status'] ?? 'Tamamlandı') as String,
      photoPath: map['photoPath'] as String?,
    );
  }
}
