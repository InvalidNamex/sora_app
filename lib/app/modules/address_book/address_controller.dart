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

  Future<void> addAddress(
    String addressName,
    String address,
    String landmark,
    double? lat,
    double? lng,
  ) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    await SupabaseService.client.from('address_book').insert({
      'userID': userId,
      'addressName': addressName,
      'address': address,
      'landmark': landmark,
      'isDefault': addresses.isEmpty,
      'latitude': ?lat,
      'longitude': ?lng,
    });
    await fetchAddresses();
  }

  Future<void> updateAddress(
    int id,
    String addressName,
    String address,
    String landmark,
    double? lat,
    double? lng,
  ) async {
    await SupabaseService.client
        .from('address_book')
        .update({
          'addressName': addressName,
          'address': address,
          'landmark': landmark,
          'latitude': ?lat,
          'longitude': ?lng,
        })
        .eq('id', id);
    await fetchAddresses();
  }

  Future<void> setDefault(int id) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;

    addresses.value = addresses
        .map((address) => address.copyWith(isDefault: address.id == id))
        .toList();

    await SupabaseService.client
        .from('address_book')
        .update({'isDefault': false})
        .eq('userID', userId);
    await SupabaseService.client
        .from('address_book')
        .update({'isDefault': true})
        .eq('id', id);
    await fetchAddresses();
  }

  Future<void> deleteAddress(int id) async {
    await SupabaseService.client.from('address_book').delete().eq('id', id);
    await fetchAddresses();
  }
}
