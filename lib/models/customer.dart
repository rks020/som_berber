class Customer {
  final String id;
  final String name;
  final String phone;
  final String notes;
  final DateTime createdAt;
  final String? profilePicturePath;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.notes = '',
    required this.createdAt,
    this.profilePicturePath,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    String? profilePicturePath,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'profilePicturePath': profilePicturePath,
    };
  }

  factory Customer.fromMap(Map<dynamic, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      notes: (map['notes'] ?? '') as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      profilePicturePath: map['profilePicturePath'] as String?,
    );
  }
}
