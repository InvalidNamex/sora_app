import '../models/order_feedback_model.dart';
import 'supabase_service.dart';

class ProductReviewSubmission {
  const ProductReviewSubmission({
    required this.orderDetailId,
    required this.rating,
    required this.review,
  });

  final int orderDetailId;
  final int rating;
  final String review;

  Map<String, dynamic> toJson() => {
    'order_detail_id': orderDetailId,
    'rating': rating,
    'review': review.trim(),
  };
}

class OrderFeedbackService {
  OrderFeedbackService._();

  static Future<Set<int>> reviewedOrderIds() async {
    final response = await SupabaseService.client
        .from('order_feedback')
        .select('order_id');
    return (response as List)
        .map((row) => (row['order_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
  }

  static Future<OrderFeedbackModel?> fetchForOrder(int orderId) async {
    final feedback = await SupabaseService.client
        .from('order_feedback')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    if (feedback == null) return null;

    final reviewRows = await SupabaseService.client
        .from('product_reviews')
        .select()
        .eq('order_id', orderId)
        .order('order_detail_id');
    final reviews = (reviewRows as List)
        .map(
          (row) => ProductReviewModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
    return OrderFeedbackModel.fromJson(
      Map<String, dynamic>.from(feedback),
      productReviews: reviews,
    );
  }

  static Future<void> submit({
    required int orderId,
    required int deliveryRating,
    required String deliveryComment,
    required List<ProductReviewSubmission> productReviews,
  }) async {
    await SupabaseService.client.rpc(
      'submit_order_feedback',
      params: {
        'p_order_id': orderId,
        'p_delivery_rating': deliveryRating,
        'p_delivery_comment': deliveryComment.trim(),
        'p_product_reviews': productReviews
            .map((review) => review.toJson())
            .toList(growable: false),
      },
    );
  }

  static Future<List<OrderFeedbackModel>> fetchForAdmin() async {
    final feedbackRows =
        (await SupabaseService.client
                .from('order_feedback')
                .select()
                .order('created_at', ascending: false))
            as List;
    if (feedbackRows.isEmpty) return const [];

    final feedback = feedbackRows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final orderIds = feedback
        .map((row) => (row['order_id'] as num).toInt())
        .toList(growable: false);
    final userIds = feedback
        .map((row) => (row['user_id'] as num).toInt())
        .toSet()
        .toList(growable: false);

    final results = await Future.wait([
      SupabaseService.client
          .from('product_reviews')
          .select()
          .inFilter('order_id', orderIds)
          .order('order_detail_id'),
      SupabaseService.client
          .from('order_detail')
          .select('id, itemName, itemNameEN')
          .inFilter('orderMasterID', orderIds),
      SupabaseService.client
          .from('users')
          .select('id, name, phone')
          .inFilter('id', userIds),
    ]);

    final detailNames = <int, String>{
      for (final row in results[1] as List)
        (row['id'] as num).toInt(): (row['itemName'] as String?) ?? '',
    };
    final users = <int, Map<String, dynamic>>{
      for (final row in results[2] as List)
        (row['id'] as num).toInt(): Map<String, dynamic>.from(row as Map),
    };
    final reviewsByOrder = <int, List<ProductReviewModel>>{};
    for (final rawRow in results[0] as List) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final orderId = (row['order_id'] as num).toInt();
      reviewsByOrder
          .putIfAbsent(orderId, () => [])
          .add(
            ProductReviewModel.fromJson(
              row,
              itemName:
                  detailNames[(row['order_detail_id'] as num).toInt()] ?? '',
            ),
          );
    }

    return feedback
        .map((row) {
          final userId = (row['user_id'] as num).toInt();
          final user = users[userId] ?? const <String, dynamic>{};
          final orderId = (row['order_id'] as num).toInt();
          return OrderFeedbackModel.fromJson(
            row,
            customerName: (user['name'] as String?) ?? '',
            customerPhone: (user['phone'] as String?) ?? '',
            productReviews: reviewsByOrder[orderId] ?? const [],
          );
        })
        .toList(growable: false);
  }
}
