# Project Sora: E-Commerce App Architecture & Guidelines
Platform Targets: Web, Android, iOS

## 1. Core Architecture & State Management
* **Design Pattern:** MVC (Model-View-Controller)
* **State Management:** GetX `^5.0.0-release-candidate-9.3.3`
* **Strict Widget Rule:** Do NOT use `StatefulWidget` ever. Use `StatelessWidget` exclusively. All state, animations, and lifecycle events (onInit, onClose) must be handled inside `GetxController` classes and observed in the UI using `Obx()`.
* **GetX Features to Utilize:** Localization, Named Routing (`GetPages`), GetX Controllers, and Dependency Injection (`Get.put` / `Get.lazyPut`).
* **Local Storage:** Use `get_storage` for persisting local preferences (Theme, Guest Cart, active Affiliate ID).

## 2. Branding & Assets
* **Colors (Must be defined in a `constants.dart` file):**
  * Light Beige: `#F1F0E9`
  * Medium Beige: `#C7B69B`
  * Dark Beige: `#B09263`
* **Typography:** `ElMeseeiri.ttf` (located in `assets/fonts`).
* **Logo:** Custom logo located in `assets/images/logo.png`.
* **Company Details (constants.dart):**
  * Support Email and Phone Number.
  * Base Domain: `https://www.sora-eg.store/`

## 3. Global Features & Workflows
* **Custom Loader:** A custom color-fill loader using the brand logo must be used throughout the app. *Crucial:* Implement this using `GetSingleTickerProviderStateMixin` in a GetX Controller, NOT a StatefulWidget.
* **Theme Toggle:** Implemented via `Get.changeThemeMode()`. Save the user's preference (Light/Dark) in `get_storage` so it persists across app restarts.
* **Guest Cart vs. Authenticated Cart:**
  * If unauthenticated: Store cart items locally in `get_storage`.
  * On Firebase Login: Trigger a sync function in the AuthController. It must read the `get_storage` cart, loop through the items, upsert them into the Supabase `cart` table (linking them to the user's new ID), and then clear the local storage.
* **Affiliate Deep Linking:** Use a deep-linking package (e.g., `app_links`). If the app is launched via a link matching `https://www.sora-eg.store/{uid}`, extract the `{uid}`, save it to `get_storage` as the `active_affiliate_id`, and apply it to the `order_master` table during the next checkout.

## 4. Screen Definitions & Navigation

**Mobile Navigation:** Android/iOS will feature an animated bottom navbar containing: Home, Cart, History, Profile, and Contact.
**Web Navigation:** Standard top header menu.

### A. Core Shopping Flow
* **SplashScreen:** Centers brand logo. Initializes GetX dependencies, Firebase, Supabase, reads Theme preference from `get_storage`, and catches any deep-links before routing to Home.
* **HomeScreen:**
  * 16:9 Carousel for banners using `carousel_slider: ^5.1.2`.
  * Horizontal scrolling list of Categories. (Clicking one filters subcategories).
  * Staggered grid view of items using `flutter_staggered_grid_view: ^0.7.0`. Load a maximum of the top 50 items for now (no infinite pagination).
  * **Sorting/UI:** Default sort is `isFeatured = true` then newest. Show flutter shimmer animations while loading. Items out of stock (`inStock == false`) must feature a tilted ribbon badge over the image.
* **ItemScreen:** Accessed via Hero animation from the grid. Displays `item_properties` (variants/sizes) as clickable horizontal pill/chip buttons (e.g., [ 50ml ] [ 100ml ]). Also displays the price, description, and an "Add to Cart" CTA.
* **CartScreen:** Lists cart items (with increment/decrement/remove). Shows Subtotal and "Proceed to Checkout". If guest, tapping Checkout forces the Firebase Auth login flow.
* **CheckoutScreen:**
  * Displays default address (from `address_book`), with a "Change" button.
  * Promo code text field (validates against `vouchers` table).
  * Order Summary (Total Price - Total Discount).
  * Payment: Strictly "Cash on Delivery" for now.
  * Action: "Place Order" inserts to `order_master` (Status: 'Pending') and `order_detail`, then clears the cart.

### B. User Management Flow
* **ProfileScreen:** Displays Avatar, Name, and Phone. Contains a list of navigation tiles:
  * My Addresses (Routes to AddressBookScreen)
  * Wishlist / Liked Items
  * Theme Toggle (Switch between Light/Dark mode)
  * **Conditional Admin Tile:** `if (user.isAdmin == true)` -> Show "Admin Dashboard" button.
  * **Conditional Affiliate Tile:** `if (user.isAffiliate == true)` -> Show "Affiliate Dashboard" button.
* **AddressBookScreen:** ListView of saved addresses. Edit/Delete/Set Default, and a FAB to Add New Address.
* **OrderHistoryScreen:** List of past orders with status. Tapping one opens **OrderDetailScreen** to see specific purchased items.
* **ContactScreen:** Displays support email and phone number. Use `url_launcher` to make these actionable (tapping phone opens dialer, tapping email opens mail app).

### C. Dashboard Screens (Role-Based)
* **AdminDashboardScreen:** Overview metrics. Routes to `OrderManagementScreen` (to change orderStatus from Pending -> Shipped -> Delivered and trigger FCM notifications) and `AffiliateManagementScreen` (to approve payout_requests or onboard new affiliates).
* **AffiliateDashboardScreen:**
  * Displays total earnings calculated from referred orders.
  * Displays their custom shareable link (`https://www.sora-eg.store/{uid}`).
  * Includes a "Request Payout/Withdrawal" button which inserts a row into the `payout_requests` table with a 'Pending' status.



Follow up:
  1- use the logo with flutter native splash
  2- use the logo image to generate icons for android app, ios app, web favicon.
  3- for all errors that are being thrown debugprint it so we can handle it.
  4- if the user is not logged in he can still browse the items, the user can login willingly from the app or forcely if he wants to place an order
  5-handle all empty lists gracefully
  6- I have added place_holder.png image to the assets folder to use when there is no image for an item and to use with the default category = all that you created. also where is the drawer in mobile app where I can find darkmode and light mode as well as to toggle languages or logout/login as well as the filters we talked about displaying products for men women or unisex along with in stock or not which should be a check box
and in case of web it has to be open.
I need you to review the md files ensuring you have left nothing out.

[HomeController] fetchItems error: PostgrestException(message: column items.created_at does not exist, code: 42703, details: , hint: null)
| don't have that column why is it being used
flutter: [HomeController] fetchItems error: type 'Null' is not a subtype of type 'int' in type cast
I don't see the banners in the home screen or the carousel?
I don't see any uniqueness to isFeatured items
add a haptic pulse to mouse hover over an item and on tap
have a cart FAB with animations for when the user adds an item to cart in item screen
I don't see the categories from supabase and their images as well

add the featured section but as we scroll we need to hide banners and featured not as they all live in a single scrollable widget but as if they collapse as we scroll.
also the banners are still not visible nor the categories.
don't tell me you have finished fixing until you verify they exist

════════ Exception caught by rendering library ═════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 34 pixels on the bottom.

The relevant error-causing widget was:
    Column Column:file:///Users/invalidnamex/Desktop/sora/lib/app/modules/home/home_view.dart:97:14