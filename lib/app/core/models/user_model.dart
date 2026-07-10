class UserModel {
  final int id;
  final String uid;
  final String name;
  final String phone;
  final String? phoneTwo;
  final bool isAffiliate;
  final bool isAdmin;
  final String? fcmTokens;

  const UserModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.phone,
    this.phoneTwo,
    this.isAffiliate = false,
    this.isAdmin = false,
    this.fcmTokens,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        uid: (json['uid'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        phoneTwo: json['phoneTwo'] as String?,
        isAffiliate: (json['isAffiliate'] as bool?) ?? false,
        isAdmin: (json['isAdmin'] as bool?) ?? false,
        fcmTokens: json['fcmTokens'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'name': name,
        'phone': phone,
        'phoneTwo': phoneTwo,
        'isAffiliate': isAffiliate,
        'isAdmin': isAdmin,
        'fcmTokens': fcmTokens,
      };
}
