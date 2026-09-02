import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

import '../../core/models/banner_model.dart';
import '../../core/models/bundle_deal_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/models/home_section_model.dart';
import '../../core/models/promotion_model.dart';
import '../../core/models/sub_category_model.dart';
import '../../core/models/video_ad_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/bundle_deal_service.dart';
import '../../core/services/media_cache_service.dart';
import '../../core/services/video_ad_service.dart';
import '../../core/utils/app_snackbar.dart';

/// View-local model combining an item with the property shown in the home feed.
class ItemWithProperty {
  final ItemModel item;
  final ItemPropertyModel? primaryProperty;
  final bool hasInStockProperty;

  const ItemWithProperty({
    required this.item,
    this.primaryProperty,
    this.hasInStockProperty = false,
  });

  /// True only when the item has properties and all are out of stock.
  bool get isOutOfStock => !hasInStockProperty;
}

class HomeController extends GetxController with WidgetsBindingObserver {
  static HomeController get to => Get.find();

  static const _cacheSchema = 4;
  static const _fallbackRefreshAge = Duration(minutes: 15);
  static const _versionPollInterval = Duration(minutes: 5);

  final banners = <BannerModel>[].obs;
  final bundleDeals = <BundleDealModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final subCategories = <SubCategoryModel>[].obs;
  final items = <ItemWithProperty>[].obs;
  final displayItems = <ItemWithProperty>[].obs;
  final activePromotions = <PromotionModel>[].obs;
  final videoAds = <VideoAdModel>[].obs;
  final homeSections = <HomeSectionModel>[].obs;
  final sectionItems = <int, List<ItemWithProperty>>{}.obs;

  final isLoadingBanners = true.obs;
  final isLoadingBundles = true.obs;
  final isLoadingVideoAds = true.obs;
  final isLoadingCategories = true.obs;
  final isLoadingItems = true.obs;
  final isLoadingHomeSections = true.obs;
  final hasItemsError = false.obs;
  final isCheckingForUpdates = false.obs;

  final selectedCategoryId = Rxn<int>();
  final selectedSubCategoryId = Rxn<int>();
  final genderFilters = <int>{0, 1, 2}.obs;
  final inStockOnly = false.obs;
  final hoveredItemId = Rxn<int>();
  final pressedItemId = Rxn<int>();

  final Map<String, List<ItemWithProperty>> _itemQueryCache = {};
  final Map<int, List<SubCategoryModel>> _subCategoryCache = {};
  final Map<int, Map<String, dynamic>> _itemRowsCache = {};
  RealtimeChannel? _contentVersionChannel;
  Timer? _versionPollTimer;
  Timer? _refreshDebounce;
  Timer? _promotionExpiryTimer;
  int _contentVersion = 0;
  int _mediaVersion = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadFromCache();
  }

  @override
  void onReady() {
    super.onReady();
    _subscribeToContentVersion();
    unawaited(checkForUpdates());
    ever(selectedCategoryId, (_) => _onCategoryChanged());
    ever(selectedSubCategoryId, (_) => _fetchItems());
    ever<Set<int>>(genderFilters, (_) => _applyFilters());
    ever<bool>(inStockOnly, (_) => _applyFilters());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _versionPollTimer?.cancel();
    _refreshDebounce?.cancel();
    _promotionExpiryTimer?.cancel();
    final channel = _contentVersionChannel;
    if (channel != null) SupabaseService.client.removeChannel(channel);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleVersionCheck(const Duration(milliseconds: 250));
    }
  }

  List<ItemWithProperty> _parseItems(List rawItems) {
    final parsed = <ItemWithProperty>[];
    for (final raw in rawItems) {
      try {
        final json = Map<String, dynamic>.from(raw as Map);
        final item = ItemModel.fromJson(json);
        if (item.id > 0) _itemRowsCache[item.id] = json;
        final props = (json['item_properties'] as List?)
            ?.map(
              (p) => ItemPropertyModel.fromJson(
                Map<String, dynamic>.from(p as Map),
              ),
            )
            .toList();
        final primary = props == null
            ? null
            : ItemPropertyModel.preferred(props);
        parsed.add(
          ItemWithProperty(
            item: item,
            primaryProperty: primary,
            hasInStockProperty:
                props?.any((property) => property.inStock) ?? false,
          ),
        );
      } catch (e) {
        debugPrint('[HomeController] item parse error: $e');
      }
    }
    return parsed;
  }

  Future<List<dynamic>> _fetchSubCategoriesForCategory(int categoryId) async {
    return await SupabaseService.client
        .from('sub_categories')
        .select()
        .eq('categoryID', categoryId);
  }

  bool _hasPersistedHomeCache(GetStorage storage) =>
      storage.read<int>(AppConstants.kHomeCacheSchema) == _cacheSchema &&
      storage.read<List>(AppConstants.kCachedBanners) != null &&
      storage.read<List>(AppConstants.kCachedPromotions) != null &&
      storage.read<List>(AppConstants.kCachedBundleDeals) != null &&
      storage.read<List>(AppConstants.kCachedVideoAds) != null &&
      storage.read<List>(AppConstants.kCachedCategories) != null &&
      storage.read<List>(AppConstants.kCachedItems) != null &&
      storage.read<List>(AppConstants.kCachedHomeSections) != null &&
      storage.read<List>(AppConstants.kCachedRecentItems) != null &&
      storage.read<List>(AppConstants.kCachedDiscountedItems) != null &&
      storage.read<int>(AppConstants.kMediaContentVersion) != null;

  bool get hasPersistedHomeCache => _hasPersistedHomeCache(GetStorage());

  bool _fallbackCacheIsFresh(GetStorage storage) {
    final timestamp = storage.read<int>(AppConstants.kHomeCacheUpdatedAt);
    if (timestamp == null) return false;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
      isUtc: true,
    );
    return DateTime.now().toUtc().difference(updatedAt) < _fallbackRefreshAge;
  }

  Future<({int? data, int? media})?> _fetchRemoteContentVersions() async {
    try {
      final rows = await SupabaseService.client
          .from('app_content_versions')
          .select('content_key, version');
      int? dataVersion;
      int? mediaVersion;
      for (final row in rows) {
        final version = (row['version'] as num?)?.toInt();
        if (row['content_key'] == 'home') dataVersion = version;
        if (row['content_key'] == 'home_media') mediaVersion = version;
      }
      return (data: dataVersion, media: mediaVersion);
    } catch (error) {
      debugPrint('[HomeController] content version check skipped: $error');
      return null;
    }
  }

  Future<List<dynamic>> _fetchPromotionRows() async {
    final response = await SupabaseService.client
        .from('promotions')
        .select()
        .or(
          'expiry_date.is.null,expiry_date.gt.${DateTime.now().toUtc().toIso8601String()}',
        )
        .order('created_at', ascending: false);
    return List<dynamic>.from(response);
  }

  Future<List<dynamic>> _fetchBannerRows() async =>
      List<dynamic>.from(await SupabaseService.client.from('banners').select());

  Future<List<dynamic>> _fetchBundleRows() async =>
      (await BundleDealService.fetchBundles())
          .map((bundle) => bundle.toJson())
          .toList(growable: false);

  Future<List<dynamic>> _fetchVideoAdRows() async =>
      (await VideoAdService.fetchAds())
          .map((ad) => ad.toJson())
          .toList(growable: false);

  Future<List<dynamic>> _fetchCategoryRows() async => List<dynamic>.from(
    await SupabaseService.client.from('categories').select(),
  );

  Future<List<dynamic>> _fetchDefaultItemRows() async => List<dynamic>.from(
    await SupabaseService.client
        .from('items')
        .select(
          'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
          'itemDescription, itemDescriptionEN, notes, notesEN, accords, '
          'accordsEN, topNotes, topNotesEN, middleNotes, middleNotesEN, '
          'baseNotes, baseNotesEN, accordPercentages, sillage, longevity, '
          'isFeatured, item_properties(*)',
        )
        .order('isFeatured', ascending: false)
        .order('id', ascending: false)
        .limit(50),
  );

  Future<List<dynamic>> _fetchRecentItemRows() async => List<dynamic>.from(
    await SupabaseService.client
        .from('items')
        .select(
          'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
          'itemDescription, itemDescriptionEN, notes, notesEN, accords, '
          'accordsEN, topNotes, topNotesEN, middleNotes, middleNotesEN, '
          'baseNotes, baseNotesEN, accordPercentages, sillage, longevity, '
          'isFeatured, item_properties(*)',
        )
        .order('id', ascending: false)
        .limit(30),
  );

  Future<List<dynamic>> _fetchDiscountedItemRows() async => List<dynamic>.from(
    await SupabaseService.client
        .from('items')
        .select(
          'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
          'itemDescription, itemDescriptionEN, notes, notesEN, accords, '
          'accordsEN, topNotes, topNotesEN, middleNotes, middleNotesEN, '
          'baseNotes, baseNotesEN, accordPercentages, sillage, longevity, '
          'isFeatured, item_properties(*)',
        )
        .order('id', ascending: false),
  );

  static const _searchItemSelect =
      'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
      'itemDescription, itemDescriptionEN, notes, notesEN, accords, accordsEN, '
      'topNotes, topNotesEN, middleNotes, middleNotesEN, baseNotes, baseNotesEN, '
      'accordPercentages, sillage, longevity, isFeatured, item_properties(*)';

  Future<List<dynamic>> _searchItemRows(String column, String pattern) async {
    return List<dynamic>.from(
      await SupabaseService.client
          .from('items')
          .select(_searchItemSelect)
          .ilike(column, pattern)
          .limit(50),
    );
  }

  Future<List<ItemWithProperty>> searchItems(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return displayItems.toList();

    final pattern = '%$query%';
    final responses = await Future.wait([
      _searchItemRows('itemName', pattern),
      _searchItemRows('itemNameEN', pattern),
      _searchItemRows('brandName', pattern),
      _searchItemRows('itemDescription', pattern),
      _searchItemRows('itemDescriptionEN', pattern),
    ]);
    final rowsById = <int, Map<String, dynamic>>{};
    for (final response in responses) {
      for (final row in response) {
        final json = Map<String, dynamic>.from(row as Map);
        final id = (json['id'] as num?)?.toInt();
        if (id != null && id > 0) rowsById[id] = json;
      }
    }
    return _applyItemFilters(_parseItems(rowsById.values.toList()));
  }

  Future<List<dynamic>> _fetchHomeSectionRows() async => List<dynamic>.from(
    await SupabaseService.client
        .from('home_sections')
        .select(
          'id, title, titleEN, section_type, item_limit, display_order, is_active, '
          'home_section_items(itemID, display_order, items('
          'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
          'itemDescription, itemDescriptionEN, notes, notesEN, accords, accordsEN, '
          'topNotes, topNotesEN, middleNotes, middleNotesEN, baseNotes, baseNotesEN, '
          'accordPercentages, sillage, longevity, isFeatured, item_properties(*)'
          '))',
        )
        .order('display_order', ascending: true)
        .order('id', ascending: true),
  );

  void _applyHomeSections(
    List<dynamic> sectionRows,
    List<dynamic> recentItemRows,
    List<dynamic> discountedItemRows,
  ) {
    final sections =
        sectionRows
            .whereType<Map>()
            .map(
              (row) =>
                  HomeSectionModel.fromJson(Map<String, dynamic>.from(row)),
            )
            .where((section) => section.id > 0 && section.isActive)
            .toList()
          ..sort((left, right) {
            final byDisplayOrder = left.displayOrder.compareTo(
              right.displayOrder,
            );
            return byDisplayOrder == 0
                ? left.id.compareTo(right.id)
                : byDisplayOrder;
          });
    final recentItems = _parseItems(recentItemRows);
    final discountedItems = _parseItems(discountedItemRows)
        .where((entry) => entry.primaryProperty?.hasDiscount == true)
        .toList(growable: false);
    final mappedItems = <int, List<ItemWithProperty>>{};
    for (final section in sections) {
      if (section.isRecentlyAdded) {
        mappedItems[section.id] = recentItems.take(section.itemLimit).toList();
        continue;
      }
      if (section.isDiscounted) {
        mappedItems[section.id] = discountedItems
            .take(section.itemLimit)
            .toList();
        continue;
      }
      final row = sectionRows.firstWhere(
        (entry) => (entry as Map)['id'] == section.id,
        orElse: () => <String, dynamic>{},
      );
      final relationshipRows =
          ((row as Map)['home_section_items'] as List?) ?? const [];
      final itemRows = relationshipRows
          .whereType<Map>()
          .map((entry) => entry['items'])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
      mappedItems[section.id] = _parseItems(
        itemRows,
      ).take(section.itemLimit).toList(growable: false);
    }
    homeSections.value = List<HomeSectionModel>.of(sections);
    sectionItems.value = mappedItems;
  }

  List<ItemWithProperty> itemsForSection(HomeSectionModel section) {
    final result = sectionItems[section.id] ?? const <ItemWithProperty>[];
    return _applyItemFilters(result);
  }

  List<ItemWithProperty> _applyItemFilters(Iterable<ItemWithProperty> source) {
    var result = source
        .where((entry) => genderFilters.value.contains(entry.item.gender))
        .toList(growable: false);
    if (inStockOnly.value) {
      result = result
          .where((entry) => !entry.isOutOfStock)
          .toList(growable: false);
    }
    return result;
  }

  /// Applies an admin reorder immediately without re-reading a potentially
  /// lagging database replica. The content-version refresh will persist the
  /// same order into the local cache on its next normal update.
  void applyHomeSectionOrder(List<int> orderedIds) {
    final positions = <int, int>{
      for (var index = 0; index < orderedIds.length; index++)
        orderedIds[index]: index,
    };
    final reordered = homeSections.toList()
      ..sort(
        (left, right) => (positions[left.id] ?? orderedIds.length).compareTo(
          positions[right.id] ?? orderedIds.length,
        ),
      );
    homeSections.value = reordered;
  }

  Future<void> checkForUpdates({bool force = false}) async {
    if (isCheckingForUpdates.value) return;
    isCheckingForUpdates.value = true;

    final storage = GetStorage();
    final hasCache = _hasPersistedHomeCache(storage);
    try {
      final remoteVersions = await _fetchRemoteContentVersions();
      final remoteVersion = remoteVersions?.data;
      if (!force && hasCache) {
        if (remoteVersion != null &&
            remoteVersion == _contentVersion &&
            remoteVersions?.media == _mediaVersion) {
          _removeExpiredPromotions();
          return;
        }
        if (remoteVersion == null && _fallbackCacheIsFresh(storage)) {
          _removeExpiredPromotions();
          return;
        }
      }

      final rows = await Future.wait<List<dynamic>>([
        _fetchPromotionRows(),
        _fetchBannerRows(),
        _fetchBundleRows(),
        _fetchVideoAdRows(),
        _fetchCategoryRows(),
        _fetchDefaultItemRows(),
        _fetchHomeSectionRows(),
        _fetchRecentItemRows(),
        _fetchDiscountedItemRows(),
      ]);
      final promotionRows = rows[0];
      final bannerRows = rows[1];
      final bundleRows = rows[2];
      final videoAdRows = rows[3];
      final categoryRows = rows[4];
      final itemRows = rows[5];
      final homeSectionRows = rows[6];
      final recentItemRows = rows[7];
      final discountedItemRows = rows[8];

      final versionsAfterFetch = await _fetchRemoteContentVersions();
      final versionAfterFetch = versionsAfterFetch?.data;
      final appliedVersion =
          remoteVersion ?? versionAfterFetch ?? _contentVersion + 1;
      final appliedMediaVersion =
          remoteVersions?.media ??
          versionsAfterFetch?.media ??
          (_mediaVersion > 0 ? _mediaVersion : 1);
      _contentVersion = appliedVersion;
      _mediaVersion = appliedMediaVersion;
      MediaCacheService.setContentVersion(appliedMediaVersion);
      _itemQueryCache.clear();
      _subCategoryCache.clear();
      _itemRowsCache.clear();

      await Future.wait<void>([
        storage.write(AppConstants.kCachedPromotions, promotionRows),
        storage.write(AppConstants.kCachedBanners, bannerRows),
        storage.write(AppConstants.kCachedBundleDeals, bundleRows),
        storage.write(AppConstants.kCachedVideoAds, videoAdRows),
        storage.write(AppConstants.kCachedCategories, categoryRows),
        storage.write(AppConstants.kCachedItems, itemRows),
        storage.write(AppConstants.kCachedHomeSections, homeSectionRows),
        storage.write(AppConstants.kCachedRecentItems, recentItemRows),
        storage.write(AppConstants.kCachedDiscountedItems, discountedItemRows),
        storage.write(AppConstants.kHomeContentVersion, appliedVersion),
        storage.write(AppConstants.kMediaContentVersion, appliedMediaVersion),
        storage.write(AppConstants.kHomeCacheSchema, _cacheSchema),
        storage.write(
          AppConstants.kHomeCacheUpdatedAt,
          DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      ]);

      activePromotions.value = promotionRows
          .whereType<Map>()
          .map((row) => PromotionModel.fromJson(Map<String, dynamic>.from(row)))
          .where((promotion) => !promotion.isExpired)
          .toList();
      banners.value = bannerRows
          .whereType<Map>()
          .map((row) => BannerModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      bundleDeals.value = bundleRows
          .whereType<Map>()
          .map(
            (row) => BundleDealModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
      videoAds.value = videoAdRows
          .whereType<Map>()
          .map((row) => VideoAdModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      categories.value = categoryRows
          .whereType<Map>()
          .map((row) => CategoryModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);

      final defaultItems = _parseItems(itemRows);
      _itemQueryCache['all'] = defaultItems;
      if (selectedCategoryId.value == null &&
          selectedSubCategoryId.value == null) {
        items.value = defaultItems;
        _applyFilters();
      }
      _applyHomeSections(homeSectionRows, recentItemRows, discountedItemRows);
      _schedulePromotionExpiry();
      hasItemsError.value = false;

      if (selectedCategoryId.value != null) {
        await _loadSelectedCategoryAfterInvalidation();
      }
      if (versionAfterFetch != null && versionAfterFetch != appliedVersion) {
        _scheduleVersionCheck(const Duration(milliseconds: 250));
      }
    } catch (error, stackTrace) {
      debugPrint('[HomeController] checkForUpdates error: $error');
      debugPrint('[HomeController] stacktrace: $stackTrace');
      if (items.isEmpty) hasItemsError.value = true;
    } finally {
      isLoadingBanners.value = false;
      isLoadingBundles.value = false;
      isLoadingVideoAds.value = false;
      isLoadingCategories.value = false;
      isLoadingItems.value = false;
      isLoadingHomeSections.value = false;
      isCheckingForUpdates.value = false;
    }
  }

  void _subscribeToContentVersion() {
    final channel = SupabaseService.client.channel('sora-home-content-version');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_content_versions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'content_key',
            value: 'home',
          ),
          callback: (payload) {
            final key = payload.newRecord['content_key'];
            final version = (payload.newRecord['version'] as num?)?.toInt();
            final changed = key == 'home'
                ? version != _contentVersion
                : key == 'home_media'
                ? version != _mediaVersion
                : false;
            if (version != null && changed) {
              _scheduleVersionCheck(const Duration(milliseconds: 200));
            }
          },
        )
        .subscribe();
    _contentVersionChannel = channel;
    _versionPollTimer = Timer.periodic(
      _versionPollInterval,
      (_) => _scheduleVersionCheck(Duration.zero),
    );
  }

  void _scheduleVersionCheck(Duration delay) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(delay, () => unawaited(checkForUpdates()));
  }

  void _removeExpiredPromotions() {
    activePromotions.removeWhere((promotion) => promotion.isExpired);
    _schedulePromotionExpiry();
  }

  void _schedulePromotionExpiry() {
    _promotionExpiryTimer?.cancel();
    final now = DateTime.now();
    final expiries =
        activePromotions
            .map((promotion) => promotion.expiryDate)
            .whereType<DateTime>()
            .where((expiry) => expiry.isAfter(now))
            .toList(growable: false)
          ..sort();
    if (expiries.isEmpty) return;
    _promotionExpiryTimer = Timer(
      expiries.first.difference(now) + const Duration(seconds: 1),
      _removeExpiredPromotions,
    );
  }

  Future<void> _loadSelectedCategoryAfterInvalidation() async {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) return;
    final rows = await _fetchSubCategoriesForCategory(categoryId);
    final parsed = rows
        .whereType<Map>()
        .map((row) => SubCategoryModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    _subCategoryCache[categoryId] = parsed;
    subCategories.value = parsed;

    final subCategoryId = selectedSubCategoryId.value;
    if (subCategoryId != null &&
        !parsed.any((subCategory) => subCategory.id == subCategoryId)) {
      selectedSubCategoryId.value = null;
    }
    await _fetchItems(force: true);
  }

  void _loadFromCache() {
    try {
      final storage = GetStorage();

      // Restore persisted filters
      final savedGenders = storage.read<List>(AppConstants.kFilterGenders);
      if (savedGenders != null) {
        genderFilters.assignAll(
          savedGenders.whereType<num>().map((gender) => gender.toInt()),
        );
      } else {
        // Migrate the old single-select filter. A missing old value meant
        // "All", which is represented by all three options being checked.
        final savedGender = storage.read<int>(AppConstants.kFilterGender);
        genderFilters.assignAll(
          savedGender == null ? {0, 1, 2} : {savedGender},
        );
        storage.write(AppConstants.kFilterGenders, genderFilters.toList());
      }
      inStockOnly.value =
          storage.read<bool>(AppConstants.kFilterInStock) ?? false;

      _contentVersion =
          storage.read<int>(AppConstants.kHomeContentVersion) ?? 0;
      _mediaVersion = storage.read<int>(AppConstants.kMediaContentVersion) ?? 0;
      MediaCacheService.setContentVersion(_mediaVersion);

      final cachedBanners = storage.read<List>(AppConstants.kCachedBanners);
      final cachedPromotions = storage.read<List>(
        AppConstants.kCachedPromotions,
      );
      final cachedBundles = storage.read<List>(AppConstants.kCachedBundleDeals);
      final cachedVideoAds = storage.read<List>(AppConstants.kCachedVideoAds);
      final cachedCategories = storage.read<List>(
        AppConstants.kCachedCategories,
      );
      final cachedItems = storage.read<List>(AppConstants.kCachedItems);
      final cachedHomeSections = storage.read<List>(
        AppConstants.kCachedHomeSections,
      );
      final cachedRecentItems = storage.read<List>(
        AppConstants.kCachedRecentItems,
      );
      final cachedDiscountedItems = storage.read<List>(
        AppConstants.kCachedDiscountedItems,
      );

      if (cachedBanners != null) {
        banners.value = cachedBanners
            .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoadingBanners.value = false;
      }
      if (cachedPromotions != null) {
        activePromotions.value = cachedPromotions
            .map(
              (e) =>
                  PromotionModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where((promotion) => !promotion.isExpired)
            .toList();
        _schedulePromotionExpiry();
      }
      if (cachedBundles != null) {
        bundleDeals.value = cachedBundles
            .map(
              (e) =>
                  BundleDealModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        isLoadingBundles.value = false;
      }
      if (cachedVideoAds != null) {
        videoAds.value = cachedVideoAds
            .whereType<Map>()
            .map((row) => VideoAdModel.fromJson(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        isLoadingVideoAds.value = false;
      }
      if (cachedCategories != null) {
        categories.value = cachedCategories
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoadingCategories.value = false;
      }
      if (cachedItems != null) {
        final parsed = _parseItems(cachedItems);
        _itemQueryCache['all'] = parsed;
        items.value = parsed;
        _applyFilters();
        isLoadingItems.value = false;
        if (cachedHomeSections != null &&
            cachedRecentItems != null &&
            cachedDiscountedItems != null) {
          _applyHomeSections(
            cachedHomeSections,
            cachedRecentItems,
            cachedDiscountedItems,
          );
          isLoadingHomeSections.value = false;
        }
      }
    } catch (e) {
      debugPrint('[HomeController] loadFromCache error: $e');
    }
  }

  Future<void> _onCategoryChanged() async {
    selectedSubCategoryId.value = null;
    subCategories.clear();
    final catId = selectedCategoryId.value;
    if (catId == null) {
      await _fetchItems();
      return;
    }
    final cached = _subCategoryCache[catId];
    if (cached != null) {
      subCategories.value = cached;
      await _fetchItems();
      return;
    }
    try {
      final response = await _fetchSubCategoriesForCategory(catId);
      final parsed = response
          .map(
            (e) =>
                SubCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      _subCategoryCache[catId] = parsed;
      subCategories.value = parsed;
    } catch (e) {
      debugPrint('[HomeController] fetchSubCategories error: $e');
      AppSnackbar.show(
        'Error Loading Subcategories',
        e.toString(),
        type: AppSnackbarType.error,
      );
      subCategories.value = [];
    }
    await _fetchItems();
  }

  String get _itemQueryKey {
    final subCategoryId = selectedSubCategoryId.value;
    if (subCategoryId != null) return 'sub:$subCategoryId';
    final categoryId = selectedCategoryId.value;
    return categoryId == null ? 'all' : 'cat:$categoryId';
  }

  Map<String, dynamic>? cachedItemRow(int itemId) => _itemRowsCache[itemId];

  void cacheItemRow(
    Map<String, dynamic> itemRow,
    List<Map<String, dynamic>> propertyRows,
  ) {
    final id = (itemRow['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;
    _itemRowsCache[id] = {...itemRow, 'item_properties': propertyRows};
  }

  Future<void> _fetchItems({bool force = false}) async {
    final cacheKey = _itemQueryKey;
    final cached = _itemQueryCache[cacheKey];
    if (!force && cached != null) {
      items.value = cached;
      hasItemsError.value = false;
      isLoadingItems.value = false;
      _applyFilters();
      return;
    }

    isLoadingItems.value = true;
    hasItemsError.value = false;
    try {
      var query = SupabaseService.client
          .from('items')
          .select(
            'id, categoryID, subCategoryID, gender, itemName, itemNameEN, brandName, '
            'itemDescription, itemDescriptionEN, notes, notesEN, accords, '
            'accordsEN, topNotes, topNotesEN, middleNotes, middleNotesEN, '
            'baseNotes, baseNotesEN, accordPercentages, sillage, longevity, '
            'isFeatured, item_properties(*)',
          );

      if (selectedSubCategoryId.value != null) {
        query = query.eq(
          'subCategoryID',
          selectedSubCategoryId.value as Object,
        );
      } else if (selectedCategoryId.value != null) {
        query = query.eq('categoryID', selectedCategoryId.value as Object);
      }

      final response = await query
          .order('isFeatured', ascending: false)
          .order('id', ascending: false)
          .limit(50);

      final parsed = _parseItems(response as List);
      _itemQueryCache[cacheKey] = parsed;
      items.value = parsed;
    } catch (e) {
      debugPrint('[HomeController] fetchItems error: $e');
      items.value = [];
      hasItemsError.value = true;
    } finally {
      _applyFilters();
      isLoadingItems.value = false;
    }
  }

  void selectCategory(int? id) => selectedCategoryId.value = id;
  void selectSubCategory(int? id) => selectedSubCategoryId.value = id;

  void toggleGenderFilter(int gender) {
    final updated = Set<int>.from(genderFilters.value);
    if (updated.contains(gender)) {
      updated.remove(gender);
    } else {
      updated.add(gender);
    }
    genderFilters.value = updated;
    GetStorage().write(AppConstants.kFilterGenders, updated.toList());
  }

  void setInStockOnly(bool v) {
    inStockOnly.value = v;
    GetStorage().write(AppConstants.kFilterInStock, v);
  }

  void setHoveredItem(int? id) => hoveredItemId.value = id;

  Future<void> pulseItemTap(int id) async {
    pressedItemId.value = id;
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (pressedItemId.value == id) pressedItemId.value = null;
  }

  void _applyFilters() {
    displayItems.value = _applyItemFilters(items);
  }

  @override
  Future<void> refresh() async {
    await checkForUpdates(force: true);
  }
}
