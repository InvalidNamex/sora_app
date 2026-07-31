class ItemSuggestionModel {
  const ItemSuggestionModel({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.status,
    required this.createdAt,
    this.brandName = '',
    this.details = '',
    this.adminNote = '',
    this.userName = '',
    this.userPhone = '',
    this.userEmail = '',
  });

  final int id;
  final int userId;
  final String itemName;
  final String brandName;
  final String details;
  final String status;
  final String adminNote;
  final DateTime createdAt;
  final String userName;
  final String userPhone;
  final String userEmail;

  factory ItemSuggestionModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] is Map
        ? Map<String, dynamic>.from(json['users'] as Map)
        : const <String, dynamic>{};
    return ItemSuggestionModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      itemName: (json['item_name'] as String?) ?? '',
      brandName: (json['brand_name'] as String?) ?? '',
      details: (json['details'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      adminNote: (json['admin_note'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userName: (user['name'] as String?) ?? '',
      userPhone: (user['phone'] as String?) ?? '',
      userEmail: (user['email'] as String?) ?? '',
    );
  }
}
