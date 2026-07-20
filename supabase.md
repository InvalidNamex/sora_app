# Supabase Configuration & Database Schema

## Initialization & Security
implementation:
    url: 'https://yuxfrgxdvuwfqwzsiezf.supabase.co'
    anonKey: 'sb_publishable_PHGiUyOddWPoaeUkpSQNMQ_RnSLOjnA'

**CRITICAL SECURITY NOTE:** Use a `.env` file for `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Do not put them in plain text.

## Table Designs

**table categories:**
* id int8 primary
* categoryName text
* categoryImage text

**table sub_categories:**
* id int8 primary
* categoryID int8 foreign key to categories.id
* subCategoryName text
* subCategoryImage text

**table users:**
* id int8 primary
* uid text (Firebase Auth ID)
* name text
* phone text
* phoneTwo text (nullable)
* isAffiliate bool default to false
* isAdmin bool default to false
* fcmTokens text
* isDeleted bool default false
* deletedAt timestamptz nullable

**account deletion:**
* `delete-account` verifies the current Firebase ID token.
* `begin_account_deletion` erases non-required account data and anonymizes
  retained order relationships.
* Active-order delivery snapshots remain only until the order reaches
  Delivered, Cancelled, or Returned; a trigger then redacts them.
* The Edge Function deletes the Firebase identity and
  `finalize_account_deletion` replaces the stored Firebase UID with a
  pseudonymous deleted-account identifier.

**table address_book:**
* id int8 primary
* userID int8 foreign key to users.id
* address text
* landmark text
* isDefault bool default to false

**table items:**
* id int8 primary
* categoryID int8 foreign key to categories.id
* subCategoryID int8 foreign key to sub_categories.id
* gender int2 default value 0 (0=Unisex, 1=Men, 2=Women)
* itemName text
* itemDescription text
* isFeatured bool default to false

**table item_properties:**
* id int8 primary
* itemID int8 foreign key to items.id
* size int4
* image text
* propertyDescription text
* price float8
* inStock bool default to true

**table cart:**
* id int8 primary
* propertyID int8 nullable foreign key to item_properties.id
* bundleID int8 nullable foreign key to bundle_deals.id
* userID int8 foreign key to users.id
* quantity int2
* created_at timestamptz
* Exactly one of propertyID or bundleID is set for each row.

**table bundle_deals:**
* id int8 primary
* title text
* titleEN text
* description text
* descriptionEN text
* bannerImage text
* dealPrice numeric
* isActive bool default true
* sortOrder int4 default 0
* createdAt timestamptz
* updatedAt timestamptz

**table bundle_deal_items:**
* id int8 primary
* bundleID int8 foreign key to bundle_deals.id
* propertyID int8 foreign key to item_properties.id
* quantity int4 (fixed quantity inside one bundle)

**storage bucket bundle_banner:**
* Public read access for horizontal bundle artwork.
* Admin uploads use Firebase-verified signed upload URLs from the
  `manage-bundles` Edge Function.

**table affiliate_codes:**
* id int8 primary
* affiliateID int8 unique foreign key to users.id
* code text unique (4-20 uppercase letters/numbers)
* customerDiscountPercentage numeric default 10
* affiliateCommissionPercentage numeric default 15
* isActive bool default true

**table customer_affiliate_attributions:**
* id int8 primary
* userID int8 foreign key to users.id
* affiliateCodeID int8 foreign key to affiliate_codes.id
* source text (link/manual)
* itemID int8 nullable
* attributedAt timestamptz
* expiresAt timestamptz
* convertedOrderID int8 nullable
* isActive bool

**table order_master:**
* id int8 primary
* userID int8 foreign key to users.id
* addressID int8 foreign key to address_book.id
* affiliateID int8 foreign key to users.id (nullable)
* affiliateCodeID int8 foreign key to affiliate_codes.id (nullable)
* affiliateCode text snapshot (nullable)
* affiliateSource text snapshot (nullable)
* affiliateDiscountPercentage numeric snapshot (nullable)
* affiliateCommissionPercentage numeric snapshot (nullable)
* affiliateCommissionAmount numeric default 0
* appliedPromoCode text snapshot (nullable)
* promoType text snapshot (nullable)
* totalPrice float8
* totalDiscount float8
* notes text
* orderStatus text default to 'Pending'
* created_at timestamptz

**table order_detail:**
* id int8 primary
* orderMasterID int8 foreign key to order_master.id
* itemPropertyID int8 foreign key to item_properties.id
* itemName text
* quantity int2
* price float8

**table vouchers:**
* id int8 primary
* voucherCode text (unique)
* voucherAmount float8 (nullable)
* voucherPercentage float8 (nullable)
* isActive bool

**table banners:**
* id int8 primary
* bannerImage text
* bannerItem int8 foreign key to items.id (nullable)

**table liked_items:**
* id int8 primary
* userID int8 foreign key to users.id
* itemID int8 foreign key to items.id

**table payout_requests:**
* id int8 primary
* affiliateID int8 foreign key to users.id
* amount float8
* status text default to 'Pending' (Options: Pending, Approved, Rejected)
* created_at timestamptzs

**table affiliate_commissions:**
* id int8 primary
* affiliateID int8 foreign key to users.id
* orderID int8 unique foreign key to order_master.id
* affiliateCodeID int8 foreign key to affiliate_codes.id
* source text (link/manual)
* eligibleSubtotal numeric
* customerDiscountAmount numeric
* commissionPercentage numeric snapshot
* amount numeric snapshot
* status text (pending/available/processing/paid/void)
* payoutRequestID int8 nullable
