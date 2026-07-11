class AddressModel {
  final int id;
  final int userId;
  final String address;
  final String landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.landmark,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['userID'] as num?)?.toInt() ?? 0,
        address: (json['address'] as String?) ?? '',
        landmark: (json['landmark'] as String?) ?? '',
        isDefault: (json['isDefault'] as bool?) ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'userID': userId,
        'address': address,
        'landmark': landmark,
        'isDefault': isDefault,
        'latitude': ?latitude,
        'longitude': ?longitude,
      };

  AddressModel copyWith({
    String? address,
    String? landmark,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) =>
      AddressModel(
        id: id,
        userId: userId,
        address: address ?? this.address,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
