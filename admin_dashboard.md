# Admin Dashboard Guidelines

## Access Control
* **Security:** The Admin Dashboard route must only be accessible if the logged-in user's `isAdmin` property in the `users` table is `true`. 
* **Navigation:** If `isAdmin == true`, add an "Admin Panel" tile to the ProfileScreen that navigates to the `AdminDashboardScreen`.

## Screens & Features

**- AdminDashboardScreen**
* **Overview:** A central hub displaying quick metrics (Total Orders, Pending Orders, Pending Payouts).
* **Navigation:** Routes to specific management screens via a GridView or ListView.

**- OrderManagementScreen**
* **Data Source:** `order_master` joined with `users` (to see who ordered).
* **UI:** A list of all orders, sortable by `created_at` and filterable by `orderStatus`.
* **Action:** Admin can tap an order to view `order_detail` and use a Dropdown to update `orderStatus` (e.g., Pending -> Processing -> Shipped -> Delivered). Updating this should trigger a GetX controller method that updates the Supabase table and ideally sends an FCM notification to the user's `fcmTokens`.

**- AffiliateManagementScreen**
* **Data Source:** `users` table (filtered by `isAffiliate == true`) and `payout_requests` table.
* **UI Tab 1 (Payouts):** List of `payout_requests` where `status` is 'Pending'. Admin can tap to "Approve" or "Reject".
* **UI Tab 2 (Users):** Ability to search users by phone or email and toggle their `isAffiliate` status to onboard new marketers.