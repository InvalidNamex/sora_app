class ProductReviewModel {
  const ProductReviewModel({
    required this.id,
    required this.orderId,
    required this.orderDetailId,
    required this.productRating,
    required this.createdAt,
    this.itemPropertyId,
    this.reviewText = '',
    this.itemName = '',
  });

  final int id;
  final int orderId;
  final int orderDetailId;
  final int? itemPropertyId;
  final int productRating;
  final String reviewText;
  final String itemName;
  final DateTime createdAt;

  factory ProductReviewModel.fromJson(
    Map<String, dynamic> json, {
    String itemName = '',
  }) => ProductReviewModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    orderId: (json['order_id'] as num?)?.toInt() ?? 0,
    orderDetailId: (json['order_detail_id'] as num?)?.toInt() ?? 0,
    itemPropertyId: (json['item_property_id'] as num?)?.toInt(),
    productRating: (json['product_rating'] as num?)?.toInt() ?? 0,
    reviewText: (json['review_text'] as String?) ?? '',
    itemName: itemName,
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class OrderFeedbackModel {
  const OrderFeedbackModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.deliveryRating,
    required this.createdAt,
    this.deliveryComment = '',
    this.customerName = '',
    this.customerPhone = '',
    this.productReviews = const [],
  });

  final int id;
  final int orderId;
  final int userId;
  final int deliveryRating;
  final String deliveryComment;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final List<ProductReviewModel> productReviews;

  factory OrderFeedbackModel.fromJson(
    Map<String, dynamic> json, {
    String customerName = '',
    String customerPhone = '',
    List<ProductReviewModel> productReviews = const [],
  }) => OrderFeedbackModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    orderId: (json['order_id'] as num?)?.toInt() ?? 0,
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    deliveryRating: (json['delivery_rating'] as num?)?.toInt() ?? 0,
    deliveryComment: (json['delivery_comment'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    customerName: customerName,
    customerPhone: customerPhone,
    productReviews: productReviews,
  );
}
