# Sora Feature Build Guide

Use this guide before building any new feature in the Sora app. It summarizes the current project structure, conventions, and the checklist needed to add features without drifting away from the existing architecture.

## Project Snapshot

Sora is a Flutter e-commerce app targeting Web, Android, and iOS.

- Framework: Flutter with Material 3
- Architecture: MVC-style modules using GetX
- State management, routing, dependency injection, and translations: `get`
- Local persistence: `get_storage`
- Authentication and messaging: Firebase Auth, Google Sign-In, Phone OTP, Firebase Messaging
- Relational data: Supabase through `supabase_flutter`
- Environment config: `.env` loaded by `flutter_dotenv`
- Main app entry: `lib/main.dart`
- Core feature code: `lib/app`

The app is bilingual. Arabic is the default locale and English is supported.

## Existing App Shape

```text
lib/
  main.dart
  firebase_options.dart
  app/
    core/
      bindings/
      constants/
      controllers/
      middleware/
      models/
      services/
      theme/
      utils/
    global_widgets/
    modules/
      feature_name/
        feature_name_view.dart
        feature_name_controller.dart
        feature_name_binding.dart
    routes/
      app_pages.dart
      app_routes.dart
    translations/
      app_translations.dart
```

Follow this layout for new work. Put reusable app-wide pieces under `core` or `global_widgets`; keep feature-specific UI and behavior inside that feature's module folder.

## Non-Negotiable Architecture Rules

- Use `StatelessWidget` for views. Do not add `StatefulWidget`.
- Put mutable state, lifecycle, animations, text controllers, and async loading inside `GetxController`.
- Use `.obs`, `Rxn<T>`, computed getters, and `Obx()` for reactive UI.
- Dispose controller-owned resources in `onClose()`.
- Use `onInit()` for synchronous setup/listeners and `onReady()` for initial UI/data loading.
- Keep Supabase access inside controllers or focused service helpers, not directly scattered through widgets.
- Keep model parsing in `lib/app/core/models`.
- Keep branding, assets, company details, and storage keys in `AppConstants`.
- Add every user-facing string to `AppTranslations` in both Arabic and English.

## Feature Build Checklist

### 1. Understand the Feature Boundary

Before coding, decide:

- Is this a routed screen, a tab inside the main shell, a reusable widget, or a controller-only behavior?
- Does it require login, admin, or affiliate access?
- Which Supabase tables are read or written?
- Does it interact with guest cart, authenticated cart, affiliate tracking, theme, or locale?
- Does it need new translations, constants, assets, or database columns?

### 2. Create or Update Models

For any new Supabase table or response shape:

- Add or update a model in `lib/app/core/models`.
- Use `fromJson(Map<String, dynamic> json)`.
- Convert nullable numeric values safely, for example `(json['price'] as num?)?.toDouble() ?? 0`.
- Keep database column names as-is in JSON parsing, including existing camel-case columns like `userID`, `itemID`, and `created_at`.
- Avoid business logic in models except small formatting or status helpers already aligned with existing patterns.

### 3. Create the Module

For a normal routed feature, create:

```text
lib/app/modules/example/example_view.dart
lib/app/modules/example/example_controller.dart
lib/app/modules/example/example_binding.dart
```

Controller pattern:

```dart
class ExampleController extends GetxController {
  static ExampleController get to => Get.find();

  final isLoading = false.obs;
  final items = <ExampleModel>[].obs;

  @override
  void onReady() {
    super.onReady();
    loadItems();
  }

  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('table_name')
          .select()
          .order('id', ascending: false);
      items.value = (response as List)
          .map((e) => ExampleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ExampleController] loadItems error: $e');
      items.value = [];
      Get.snackbar('error'.tr, 'error_loading'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
```

Binding pattern:

```dart
class ExampleBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<ExampleController>(() => ExampleController()),
      ];
}
```

View pattern:

```dart
class ExampleView extends GetView<ExampleController> {
  const ExampleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CustomLoader());
      }

      return ListView(
        children: [
          // Build feature UI here.
        ],
      );
    });
  }
}
```

### 4. Register Routes

For routed screens:

1. Add a route constant in `lib/app/routes/app_routes.dart`.
2. Import the view and binding in `lib/app/routes/app_pages.dart`.
3. Add a `GetPage`.
4. Add middleware when needed:
   - `AuthGuard()` for logged-in users only
   - `AdminGuard()` for admins only
   - `AffiliateGuard()` for affiliates only

Example:

```dart
GetPage(
  name: Routes.example,
  page: () => const ExampleView(),
  binding: ExampleBinding(),
  middlewares: [AuthGuard()],
),
```

For tabs in the main shell, update `AppScaffold`, `NavController`, drawer labels, bottom navigation items, and translations together.

### 5. Wire Dependency Lifetime Correctly

Use `AppBinding.init()` only for long-lived controllers or tab controllers that should survive route changes.

Use route bindings for screen-specific controllers. This keeps memory and side effects scoped to the screen.

Current permanent controllers:

- `AuthController`
- `CartController`
- `NavController`
- `SettingsController` is put in `main.dart`

Current lazy app-level tab controllers:

- `HomeController`
- `HistoryController`

### 6. Handle Auth and Security

Firebase Auth is the identity source. Supabase stores relational user data in the `users` table and expects RLS to be configured in Supabase.

When building authenticated features:

- Read the current app user from `AuthController.to.currentUser.value`.
- Use `AuthController.to.isLoggedIn` for quick checks.
- Do not trust client-side route guards as the only security layer. Supabase RLS must enforce access.
- For Google sign-in, Supabase auth is linked through the Google ID token.
- Phone auth currently has a TODO for Supabase OIDC handoff. Be careful with features that require Supabase user JWT claims for phone users.

### 7. Work With Supabase Carefully

Use `SupabaseService.client` for all Supabase calls.

Known tables from the current docs:

- `categories`
- `sub_categories`
- `users`
- `address_book`
- `items`
- `item_properties`
- `cart`
- `order_master`
- `order_detail`
- `vouchers`
- `banners`
- `liked_items`
- `payout_requests`

Important existing quirks:

- Some code falls back from typo table names like `catergories` and `sub_catergories` to the corrected names. Prefer the corrected names in new work unless compatibility is required.
- Cart table column `itemID` points to `item_properties.id`, not `items.id`.
- User-facing order statuses currently include `Pending`, `Processing`, `Shipped`, and `Delivered`.
- Affiliate tracking stores the Firebase UID in `get_storage` under `AppConstants.kActiveAffiliateId`, then checkout resolves it to `users.id`.

### 8. Preserve Guest vs Authenticated Behavior

Cart behavior is split:

- Guest cart: `get_storage` under `AppConstants.kGuestCart`
- Authenticated cart: Supabase `cart` table
- Login sync: `AuthController` upserts guest cart rows to Supabase, clears local storage, then exposes `currentUser`

Any feature that changes cart state should go through `CartController` unless there is a clear reason not to.

### 9. Add UI the Sora Way

Use the existing theme and responsive utilities:

- Theme: `AppTheme`
- Brand constants: `AppConstants`
- Responsive breakpoints: `Responsive`
- Shared shell: `AppScaffold`
- Drawer/filter/settings UI: `AppDrawer`
- Loader: `CustomLoader`

UI expectations:

- Support both mobile and desktop/web layouts when the feature is user-facing.
- Use Material icons and familiar Material controls.
- Keep views reactive with `Obx`.
- Show loading and empty states.
- Use `Get.snackbar()` for lightweight success/error feedback.
- Use the brand colors and fonts from constants/theme.
- Do not hard-code visible strings in widgets. Use translation keys.

### 10. Add Translations

Every new visible label, button, error, empty state, and snackbar message should be added to:

```text
lib/app/translations/app_translations.dart
```

Add both:

- Arabic under `ar`
- English under `en`

Use keys in UI:

```dart
Text('example_key'.tr)
```

### 11. Update Constants and Assets

If a feature needs shared values, add them to:

```text
lib/app/core/constants/app_constants.dart
```

If a feature needs new images or files:

- Put images in `assets/images/`.
- Keep fonts in `assets/fonts/`.
- Confirm `pubspec.yaml` includes the asset path.
- Use constants for repeated asset paths.

### 12. Navigation Rules

Use named routes for screen navigation:

```dart
Get.toNamed(Routes.example);
Get.offAllNamed(Routes.home);
```

Use tab index changes only for the main shell tabs:

```dart
NavController.to.setIndex(0);
```

Use `Get.arguments` only when the existing route pattern already does so. Prefer passing stable IDs and loading fresh data where possible.

### 13. Testing and Verification

Before considering a feature done, run:

```bash
flutter analyze
flutter test
```

For user-facing UI, also run the app on at least one target:

```bash
flutter run -d chrome
```

Manual checks:

- Feature works for Arabic and English.
- Feature works in light and dark theme.
- Mobile layout does not overflow.
- Desktop/web layout is usable.
- Logged-out users are redirected or handled correctly.
- Admin/affiliate routes reject unauthorized users.
- Loading, empty, success, and error states are visible.
- Supabase writes use the correct user ID and table columns.

## Common Feature Recipes

### Add a Protected User Screen

1. Create model if needed.
2. Create `feature_controller.dart`, `feature_view.dart`, and `feature_binding.dart`.
3. Add route constant to `app_routes.dart`.
4. Register `GetPage` in `app_pages.dart` with `AuthGuard()`.
5. Add navigation entry where appropriate.
6. Add translations.
7. Run analyzer and tests.

### Add an Admin Feature

1. Create the module under `lib/app/modules/admin/feature_name`.
2. Register the route with `AdminGuard()`.
3. Query only the tables needed for the admin action.
4. Update Supabase rows through controller methods.
5. Add clear success and error snackbars.
6. Make sure Supabase RLS and admin privileges are configured server-side.

### Add a New Main Tab

1. Create the view and controller.
2. Register the controller in `AppBinding.init()` if tab state should persist.
3. Add the view to `_tabs` in `AppScaffold`.
4. Update `NavController` logic if needed.
5. Add mobile bottom nav item, desktop nav label, and drawer tile.
6. Add translations.
7. Check mobile and desktop layout.

### Add a Supabase-Backed List

1. Create a model.
2. Controller owns `items`, `isLoading`, and optional `hasError`.
3. Load in `onReady()`.
4. Parse defensively.
5. Show loading, empty, error, and data UI.
6. Add retry action if failure blocks the user.

## Final Review Checklist

- No new `StatefulWidget`.
- Controller owns all state and disposes resources.
- Routes and bindings are registered.
- Correct middleware is applied.
- Strings are translated in Arabic and English.
- Supabase table and column names match the schema.
- Guest/auth behavior is preserved.
- Theme, constants, and shared widgets are reused.
- `flutter analyze` passes or any remaining warnings are documented.
- `flutter test` passes or any failing tests are explained.

