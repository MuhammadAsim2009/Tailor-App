class ProfileModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;

  ProfileModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      shopName: map['shopName'],
      ownerName: map['ownerName'],
      phone: map['phone'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
    };
  }
}
