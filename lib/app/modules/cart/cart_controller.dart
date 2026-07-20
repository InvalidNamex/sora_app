import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/models/bundle_deal_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/bundle_deal_service.dart';
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
  final bundleItems = <BundleCartItemModel>[].obs;
  final isLoading = false.obs;
  final _storage = GetStorage();

  int get totalItems =>
      cartItems.fold(0, (sum, e) => sum + e.quantity) +
      bundleItems.fold(0, (sum, e) => sum + e.quantity);
  double get totalPrice =>
      cartItems.fold(0.0, (sum, e) => sum + e.subtotal) +
      bundleItems.fold(0.0, (sum, e) => sum + e.subtotal);
  double get regularTotalPrice =>
      cartItems.fold(0.0, (sum, e) => sum + e.subtotal) +
      bundleItems.fold(0.0, (sum, e) => sum + e.regularSubtotal);
  double get bundleSavings => regularTotalPrice - totalPrice;
  bool get isEmpty => cartItems.isEmpty && bundleItems.isEmpty;

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
    } else {
      cartItems.value = rawList
          .whereType<Map>()
          .map(
            (row) =>
                CartItemModel.fromLocalJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    }
    final rawBundles = _storage.read<List>(AppConstants.kGuestBundleCart);
    bundleItems.value = (rawBundles ?? const [])
        .whereType<Map>()
        .map(
          (row) =>
              BundleCartItemModel.fromLocalJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> _loadFromSupabase() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      final responses = await Future.wait([
        SupabaseService.client
            .from('cart')
            .select(
              'id, itemID, quantity, '
              'item_properties!propertyID(id, itemID, size, image, price), '
              'items(itemName, itemNameEN, '
              'item_properties(id, image, price, isDefault, inStock))',
            )
            .eq('userID', userId)
            .not('propertyID', 'is', null),
        SupabaseService.client
            .from('cart')
            .select(
              'id, bundleID, quantity, bundle_deals!bundleID('
              '${BundleDealService.bundleSelect})',
            )
            .eq('userID', userId)
            .not('bundleID', 'is', null),
      ]);
      cartItems.value = (responses[0] as List)
          .map((e) => CartItemModel.fromSupabaseJson(e as Map<String, dynamic>))
          .toList();
      bundleItems.value = (responses[1] as List)
          .map(
            (e) =>
                BundleCartItemModel.fromSupabaseJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('[CartController] loadFromSupabase error: $e');
      cartItems.value = [];
      bundleItems.value = [];
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
      _addToLocalStorage(
        prop,
        itemName,
        quantity,
        displayProperty: displayProperty,
      );
    }
  }

  Future<void> addBundle(BundleDealModel bundle, int quantity) async {
    if (quantity <= 0) return;
    if (AuthController.to.isLoggedIn) {
      await _addBundleToSupabase(bundle.id, quantity);
    } else {
      final existing = bundleItems.firstWhereOrNull(
        (entry) => entry.bundle.id == bundle.id,
      );
      if (existing == null) {
        bundleItems.add(
          BundleCartItemModel(cartId: 0, bundle: bundle, quantity: quantity),
        );
      } else {
        existing.quantity += quantity;
        bundleItems.refresh();
      }
      _persistLocalBundles();
    }
  }

  Future<void> _addBundleToSupabase(int bundleId, int quantity) async {
    final userId = AuthController.to.currentUser.value!.id;
    final client = SupabaseService.client;
    final existing = await client
        .from('cart')
        .select('id, quantity')
        .eq('userID', userId)
        .eq('bundleID', bundleId)
        .maybeSingle();
    if (existing == null) {
      await client.from('cart').insert({
        'userID': userId,
        'bundleID': bundleId,
        'quantity': quantity,
      });
    } else {
      final next = ((existing['quantity'] as num?)?.toInt() ?? 0) + quantity;
      await client
          .from('cart')
          .update({'quantity': next})
          .eq('id', existing['id'] as Object);
    }
    await _loadFromSupabase();
  }

  void _addToLocalStorage(
    ItemPropertyModel prop,
    String itemName,
    int quantity, {
    ItemPropertyModel? displayProperty,
  }) {
    final existing = cartItems.firstWhereOrNull(
      (e) => e.itemPropertyId == prop.id,
    );
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      final display = displayProperty ?? prop;
      cartItems.add(
        CartItemModel(
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
        ),
      );
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
          .update({'quantity': item.quantity})
          .eq('id', item.cartId);
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
          .update({'quantity': item.quantity})
          .eq('id', item.cartId);
    } else {
      _persistLocal();
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> remove(CartItemModel item) async {
    cartItems.remove(item);
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client.from('cart').delete().eq('id', item.cartId);
    } else {
      _persistLocal();
    }
  }

  Future<void> incrementBundle(BundleCartItemModel item) async {
    item.quantity++;
    bundleItems.refresh();
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client
          .from('cart')
          .update({'quantity': item.quantity})
          .eq('id', item.cartId);
    } else {
      _persistLocalBundles();
    }
  }

  Future<void> decrementBundle(BundleCartItemModel item) async {
    if (item.quantity <= 1) {
      await removeBundle(item);
      return;
    }
    item.quantity--;
    bundleItems.refresh();
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client
          .from('cart')
          .update({'quantity': item.quantity})
          .eq('id', item.cartId);
    } else {
      _persistLocalBundles();
    }
  }

  Future<void> removeBundle(BundleCartItemModel item) async {
    bundleItems.remove(item);
    if (AuthController.to.isLoggedIn) {
      await SupabaseService.client.from('cart').delete().eq('id', item.cartId);
    } else {
      _persistLocalBundles();
    }
  }

  // ── Clear (after order placed) ────────────────────────────────────────────

  Future<void> clear() async {
    if (AuthController.to.isLoggedIn) {
      final userId = AuthController.to.currentUser.value!.id;
      await SupabaseService.client.from('cart').delete().eq('userID', userId);
    } else {
      await _storage.remove(AppConstants.kGuestCart);
      await _storage.remove(AppConstants.kGuestBundleCart);
    }
    cartItems.clear();
    bundleItems.clear();
  }

  void _persistLocal() {
    _storage.write(
      AppConstants.kGuestCart,
      cartItems.map((e) => e.toLocalJson()).toList(),
    );
  }

  void _persistLocalBundles() {
    _storage.write(
      AppConstants.kGuestBundleCart,
      bundleItems.map((entry) => entry.toLocalJson()).toList(),
    );
  }
}
