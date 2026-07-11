import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_controller.dart';

/// Manages the shopping cart for both guest and authenticated users.
///
/// Guest mode: items are persisted in [get_storage] with full display metadata.
/// Auth mode: items live in the Supabase [cart] table.
///
/// The [ever] listener on [AuthController.currentUser] reloads the cart
/// automatically after login (after guest-cart sync has completed).
class CartController extends GetxController {
  static CartController get to => Get.find();

  final cartItems = <CartItemModel>[].obs;
  final isLoading = false.obs;
  final _storage = GetStorage();

  int get totalItems =>
      cartItems.fold(0, (sum, e) => sum + e.quantity);
  double get totalPrice =>
      cartItems.fold(0, (sum, e) => sum + e.subtotal);

  @override
  void onInit() {
    super.onInit();
    _loadFromLocalStorage();
    ever(AuthController.to.currentUser, (user) {
      if (user != null) {
        _loadFromSupabase();
      } else {
        _loadFromLocalStorage();
      }
    });
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  void _loadFromLocalStorage() {
    final rawList = _storage.read<List>(AppConstants.kGuestCart);
    if (rawList == null) {
      cartItems.value = [];
      return;
    }
    cartItems.value = rawList
        .cast<Map<String, dynamic>>()
        .map(CartItemModel.fromLocalJson)
        .toList();
  }

  Future<void> _loadFromSupabase() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('cart')
          .select('id, itemID, quantity, item_properties!propertyID(id, itemID, size, image, price), items(itemName, itemNameEN, item_properties(id, image, price, isDefault, inStock))')
          .eq('userID', userId);
      cartItems.value = (response as List)
          .map((e) => CartItemModel.fromSupabaseJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CartController] loadFromSupabase error: $e');
      cartItems.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCart() async {
    if (AuthController.to.isLoggedIn) {
      await _loadFromSupabase();
    } else {
      _loadFromLocalStorage();
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> addItem(
    ItemPropertyModel prop,
    String itemName,
    int quantity, {
    ItemPropertyModel? displayProperty,
  }) async {
    if (AuthController.to.isLoggedIn) {
      await _addToSupabase(prop.id, prop.itemId, quantity);
    } else {
      _addToLocalStorage(prop, itemName, quantity, displayProperty: displayProperty);
    }
  }

  void _addToLocalStorage(
    ItemPropertyModel prop,
    String itemName,
    int quantity, {
    ItemPropertyModel? displayProperty,
  }) {
    final existing =
        cartItems.firstWhereOrNull((e) => e.itemPropertyId == prop.id);
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      final display = displayProperty ?? prop;
      cartItems.add(CartItemModel(
        cartId: 0,
        itemPropertyId: prop.id,
        itemId: prop.itemId,
        itemName: itemName,
        image: prop.image,
        displayImage: display.image,
        sizeMl: prop.sizeMl,
        price: prop.price,
        displayPrice: display.price,
        quantity: quantity,
      ));
    }
    _persistLocal();
  }

  Future<void> _addToSupabase(int propertyId, int itemId, int quantity) async {
    final userId = AuthController.to.currentUser.value!.id;
    final client = SupabaseService.client;

    final existing = await client
        .from('cart')
        .select()
        .eq('userID', userId)
        .eq('propertyID', propertyId)
        .maybeSingle();

    if (existing != null) {
      final currentQty = existing['quantity'] as int;
      await client
          .from('cart')
          .update({'quantity': currentQty + quantity})
          .eq('id', existing['id'] as Object);
    } else {
      await client.from('cart').insert({
        'userID': userId,
        'propertyID': propertyId,
        'itemID': itemId,
        'quantity': quantity,
      });
    }
    await _loadFromSupabase();
  }

  // ── Quantity ──────────────────────────────────────────────────────────────

  Future<void> increment(CartItemModel item) async {
    item.quantity++;
    cartItems.refresh();
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client
          .from('cart')
          .update({'quantity': item.quantity}).eq('id', item.cartId);
    } else {
      _persistLocal();
    }
  }

  Future<void> decrement(CartItemModel item) async {
    if (item.quantity <= 1) {
      await remove(item);
      return;
    }
    item.quantity--;
    cartItems.refresh();
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client
          .from('cart')
          .update({'quantity': item.quantity}).eq('id', item.cartId);
    } else {
      _persistLocal();
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> remove(CartItemModel item) async {
    cartItems.remove(item);
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client
          .from('cart')
          .delete()
          .eq('id', item.cartId);
    } else {
      _persistLocal();
    }
  }

  // ── Clear (after order placed) ────────────────────────────────────────────

  Future<void> clear() async {
    if (AuthController.to.isLoggedIn) {
      final userId = AuthController.to.currentUser.value!.id;
      await SupabaseService.client
          .from('cart')
          .delete()
          .eq('userID', userId);
    } else {
      await _storage.remove(AppConstants.kGuestCart);
    }
    cartItems.clear();
  }

  void _persistLocal() {
    _storage.write(
      AppConstants.kGuestCart,
      cartItems.map((e) => e.toLocalJson()).toList(),
    );
  }
}
