import '../models/return_request_model.dart';
import 'supabase_service.dart';

class ReturnRequestService {
  ReturnRequestService._();

  static Future<List<ReturnRequestModel>> forOrder(int orderId) async {
    final rows = await SupabaseService.client
        .from('return_requests')
        .select('*, order_detail(itemName), order_master(delivered_at)')
        .eq('order_id', orderId)
        .order('created_at');
    return (rows as List)
        .map(
          (r) =>
              ReturnRequestModel.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<void> create({
    required int orderId,
    required int detailId,
    required int userId,
    required String name,
    required String phone,
    required bool hasWhatsapp,
    required String reason,
  }) async {
    await SupabaseService.client.from('return_requests').insert({
      'order_id': orderId,
      'order_detail_id': detailId,
      'user_id': userId,
      'customer_name': name.trim(),
      'customer_phone': phone.trim(),
      'has_whatsapp': hasWhatsapp,
      'reason': reason.trim(),
    });
  }

  static Future<List<ReturnRequestModel>> forAdmin() async {
    final rows = await SupabaseService.client
        .from('return_requests')
        .select(
          '*, order_detail(itemName), order_master(delivered_at), users(name, phone)',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (r) =>
              ReturnRequestModel.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<void> updateStatus(
    int id,
    String status, {
    String? note,
  }) async {
    await SupabaseService.client
        .from('return_requests')
        .update({'status': status, if (note != null) 'admin_note': note})
        .eq('id', id);
  }
}
