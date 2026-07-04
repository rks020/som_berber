class Barber {
  final String id;
  final String name;
  final String phone;
  final String? profilePicturePath;

  Barber({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePicturePath,
  });

  Barber copyWith({
    String? id,
    String? name,
    String? phone,
    String? profilePicturePath,
  }) {
    return Barber(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profile_picture_path': profilePicturePath,
    };
  }

  factory Barber.fromMap(Map<dynamic, dynamic> map) {
    return Barber(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      profilePicturePath: (map['profile_picture_path'] ?? map['profilePicturePath']) as String?,
    );
  }
}
