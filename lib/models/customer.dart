class Customer {
  final String id;
  final String name;
  final String phone;
  final String notes;
  final DateTime createdAt;
  final String? profilePicturePath;
  final String? fcmToken;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.notes = '',
    required this.createdAt,
    this.profilePicturePath,
    this.fcmToken,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    String? profilePicturePath,
    String? fcmToken,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'profile_picture_path': profilePicturePath,
      'fcm_token': fcmToken,
    };
  }

  factory Customer.fromMap(Map<dynamic, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      notes: (map['notes'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      profilePicturePath: map['profile_picture_path'] as String?,
      fcmToken: map['fcm_token'] as String?,
    );
  }
}
