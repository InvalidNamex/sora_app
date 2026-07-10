class AddressModel {
  final int id;
  final int userId;
  final String address;
  final String landmark;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.landmark,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['userID'] as num?)?.toInt() ?? 0,
        address: (json['address'] as String?) ?? '',
        landmark: (json['landmark'] as String?) ?? '',
        isDefault: (json['isDefault'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'userID': userId,
        'address': address,
        'landmark': landmark,
        'isDefault': isDefault,
      };

  AddressModel copyWith({String? address, String? landmark, bool? isDefault}) =>
      AddressModel(
        id: id,
        userId: userId,
        address: address ?? this.address,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
      );
}
