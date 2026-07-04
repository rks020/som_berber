class Service {
  final String id;
  final String name;
  final double price;

  Service({required this.id, required this.name, required this.price});

  Service copyWith({String? id, String? name, double? price}) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price};
  }

  factory Service.fromMap(Map<dynamic, dynamic> map) {
    return Service(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }
}
