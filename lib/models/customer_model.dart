import 'measurement_model.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final MeasurementModel? measurements;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.measurements,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'measurements': measurements?.toJson(), // Store as JSON string in DB
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      measurements: map['measurements'] != null
          ? MeasurementModel.fromJson(map['measurements'])
          : null,
    );
  }
}
