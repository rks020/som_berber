class AppointmentModel {
  final String id;
  final String title;
  final String category;
  final DateTime dateTime;
  final int durationMinutes;
  final double price;
  final String additionalPeople;
  final String colorHex;
  final String status;
  final String? customerId;
  final String? barberId;

  AppointmentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.dateTime,
    required this.durationMinutes,
    required this.price,
    this.additionalPeople = '',
    required this.colorHex,
    this.status = 'onaylandı',
    this.customerId,
    this.barberId,
  });

  AppointmentModel copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? dateTime,
    int? durationMinutes,
    double? price,
    String? additionalPeople,
    String? colorHex,
    String? status,
    String? customerId,
    String? barberId,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      additionalPeople: additionalPeople ?? this.additionalPeople,
      colorHex: colorHex ?? this.colorHex,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date_time': dateTime.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'price': price,
      'additional_people': additionalPeople,
      'color_hex': colorHex,
      'status': status,
      'customer_id': customerId,
      'barber_id': barberId,
    };
  }

  factory AppointmentModel.fromMap(Map<dynamic, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      dateTime: DateTime.parse(map['dateTime'] ?? map['date_time'] as String).toLocal(),
      durationMinutes: (map['duration_minutes'] ?? map['durationMinutes'] ?? 60 as num).toInt(),
      price: (map['price'] as num).toDouble(),
      additionalPeople: (map['additional_people'] ?? map['additionalPeople'] ?? '') as String,
      colorHex: (map['color_hex'] ?? map['colorHex'] ?? '#4CAF50') as String,
      status: map['status'] as String? ?? 'onaylandı',
      customerId: map['customer_id'] as String?,
      barberId: map['barber_id'] as String?,
    );
  }
}
