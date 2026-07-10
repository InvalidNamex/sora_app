import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/models/address_model.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_controller.dart';

class AddressController extends GetxController {
  static AddressController get to => Get.find();

  final addresses = <AddressModel>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('address_book')
          .select()
          .eq('userID', userId)
          .order('isDefault', ascending: false);
      addresses.value = (response as List)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AddressController] fetchAddresses error: $e');
      addresses.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAddress(String address, String landmark) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    await SupabaseService.client.from('address_book').insert({
      'userID': userId,
      'address': address,
      'landmark': landmark,
      'isDefault': addresses.isEmpty,
    });
    await fetchAddresses();
  }

  Future<void> updateAddress(
      int id, String address, String landmark) async {
    await SupabaseService.client
        .from('address_book')
        .update({'address': address, 'landmark': landmark}).eq('id', id);
    await fetchAddresses();
  }

  Future<void> setDefault(int id) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    await SupabaseService.client
        .from('address_book')
        .update({'isDefault': false}).eq('userID', userId);
    await SupabaseService.client
        .from('address_book')
        .update({'isDefault': true}).eq('id', id);
    await fetchAddresses();
  }

  Future<void> deleteAddress(int id) async {
    await SupabaseService.client
        .from('address_book')
        .delete()
        .eq('id', id);
    await fetchAddresses();
  }
}
