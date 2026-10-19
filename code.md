# Restaurant Management System — Code Documentation

**Project:** Lumière Dining (Restaurant Management) — Ruby on Rails 8.1
**Last updated:** 10/18/2026

---

## 1. Project Overview

A full-featured POS + Inventory management system for a restaurant.

- **Front-of-house (FO):** table reservations, floor-map seating, in-person ordering (waiter), pre-orders (table booked online), payments (all currencies + Stripe + VietQR QR), customer queue/walk-in management, reviews.
- **Back-of-house (BO):** kitchen queue (pending → accepted → preparing → ready → served), waste reports, low-stock requests, stock transactions, restock tasks, ingredient management.
- **Management:** dashboards (performance, revenue, inventory, occupancy), role-based access (admin, inventory_manager, kitchen_staff, receptionist, waiter, customer), member-tier loyalty, real-time notifications (Turbo Streams).

The system is deeply **event-driven**: orders trigger kitchen notifications; stock deducts automatically on order acceptance; waste reports may auto-generate restock tasks; pre-orders released to kitchen at T-10.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Database | PostgreSQL 8.1 |
| Background jobs | Sidekiq 8.1 + Redis |
| Queue adapter | solid_queue (prod), async (dev) |
| Broadcasts | Action Cable + Turbo Streams |
| Auth | Devise + devise-jwt |
| Authorization | Pundit |
| Pagination | Kaminari |
| PDF | Prawn + Prawn::Table |
| Payments | Stripe, VietQR |
| Frontend | Hotwire/Turbo/Stimulus, Importmap, Tailwind, Konva.js |
| Deployment | Kamal, Docker, Thruster |

---

## 3. Architecture

```
Browser → Routes (config/routes.rb)
   ↓
ApplicationController (devise, Pundit, notifications)
   ↓
NamespaceControllers (Inventory:: / Kitchen:: / Admin::)
   ↓
ResourcefulControllers (Orders, Foods, Ingredients, Reservations, etc.)
   ↓
Models (AR callbacks, state machines, scopes)
   ↓
Services (StockService, StockAvailability, CustomerQueueManager, RestaurantPerformanceService, InvoicePdf)
   ↓
Jobs (PreorderReleaseJob, PreorderReleaseSweepJob, ReservationConfirmationJob)
   ↓
Mailers, Notifications (Notification + Turbo Streams)
```

### Authorization Strategy (Pundit)
- Every controller uses `authorize <Record>, :action?` and `policy_scope(<Model>)`.
- `ApplicationController` rescues `Pundit::NotAuthorizedError` → renders 403.

### Layouts
- `app/views/layouts/application.html.erb` — main app layout.
- `layouts/devise.html.erb` — Devise login/signup pages.
- `layouts/mailer.html.erb` / `mailer.text.erb` — email layout.

---

## 4. Directory Structure (app/)

```
app/
├── controllers/
│   ├── application_controller.rb          # devise, Pundit, notifications helpers
│   ├── dashboards_controller.rb           # Admin overview + performance report
│   ├── orders_controller.rb               # Full order CRUD + status updates
│   ├── order_items_controller.rb          # Add items, mark served/cancelled
│   ├── bills_controller.rb                # Invoice PDF + payment show
│   ├── preorders_controller.rb            # Customer table bookings + pre-order
│   ├── payments_controller.rb             # Stripe/QR checkout + confirm
│   ├── reservations_controller.rb         # Public booking form
│   ├── reviews_controller.rb              # Customer reviews
│   ├── notifications_controller.rb        # User notification list
│   ├── promotions_controller.rb           # Promotions management
│   ├── menus_controller.rb                # Public menu page
│   ├── foods_controller.rb                # Food CRUD
│   ├── food_variants_controller.rb        # Dish variants (size/spice/etc.)
│   ├── ingredients_controller.rb          # Inventory items
│   ├── categories_controller.rb           # Menu categories
│   ├── tables_controller.rb               # Table floor-plan (admin)
│   ├── table_types_controller.rb          # Table category (square/round)
│   ├── areas_controller.rb                # Physical areas (rooms/floor)
│   ├── users_controller.rb                # Staff directory
│   ├── users/{sessions,passwords,registrations}_controller.rb
│   ├── kitchen/ (kitchen_staff/admin only)
│   ├── inventory/ (inventory_manager/admin only)
│   ├── admin/ (receptionists/admins)
│   └── helpers/
├── models/           # 27 ActiveRecord models (§5)
├── services/         # 6 service classes (§7)
├── jobs/             # 3 background jobs (§8)
├── mailers/          # 2 mailers (§9)
├── views/            # 220 view templates (§10)
├── javascript/       # Stimulus controllers (~17)
└── helpers/          # ~20 view helpers
```

---

## 5. Domain Models — Food & Recipes

#### `Food` (app/models/food.rb)
- **Associations:** `belongs_to :category`, `has_many :food_variants` (destroy), `has_many :recipe_items`, `has_many :ingredients` (through recipe), `has_many :order_items`, `has_one_attached :image`.
- **Enums:** `status: active(0)/inactive(1)`.
- **Validations:** `name` unique within category (case-insensitive); `base_price` ≥ 0; `description` ≤ 2000 chars.
- **Custom validation:** `image_type_and_size` — PNG/JPEG/WEBP, < 5MB.
- **Purpose:** Dish on menu, priced in USD.

#### `FoodVariant` (app/models/food_variant.rb)
- **Associations:** `belongs_to :food`, `has_many :recipe_items`, `has_many :order_items`.
- **Validations:** `name` unique within food; `price_adjustment` present & numeric.
- **Computed:** `final_price = food.base_price + price_adjustment`.
- **Purpose:** Same dish with size/spice/portion variants + additional cost.

#### `Ingredient` (app/models/ingredient.rb)
- **Associations:** `has_many :recipe_items` (restrict_with_error), `has_many :foods` (through recipe), `has_many :stock_transactions`/`restock_tasks`/`low_stock_requests`/`waste_reports` (restrict_with_error).
- **Enums:** `status: in_stock(0)/low_stock(1)/out_of_stock(2)`.
- **Scopes:** `needs_restock`, `by_category`, `active`/`archived`, `search` (ILIKE), `by_status`, `low_stock`, `out_of_stock`.
- **Attributes:** `initial_quantity` (decimal, default 0), `unit`, `category` (enum-like string), `unit_cost`, `current_quantity`, `low_stock_threshold`, `reorder_quantity`.
- **Constants:** `CATEGORIES = %w[meat seafood dairy produce dry bakery beverage other]`.
- **Callbacks:** `before_save :sync_status!` — auto-updates status by comparing current_quantity vs low_stock_threshold.
- **Custom methods:** `suggested_reorder_quantity` — returns `reorder_quantity` if positive, else gap = threshold − current, else `max(threshold, 1)`.
- **Purpose:** Core inventory item; every stock movement flows through here.

#### `Category` (app/models/category.rb)
- **Associations:** `has_many :foods`.
- **Validations:** `name` present & unique (case-insensitive).
- **Purpose:** Menu grouping.

#### `RecipeItem` (app/models/recipe_item.rb)
- **Associations:** `belongs_to :food`, `belongs_to :food_variant` (optional), `belongs_to :ingredient`.
- **Validations:** `quantity_required` > 0; `ingredient_id` unique per (food_id, food_variant_id).
- **Custom validation:** `variant_belongs_to_food` — variant must belong to same food.
- **Class method:** `for_item(food_id:, variant_id: nil)` — variant recipe rows if variant_id present; else base recipe rows.
- **Purpose:** "Recipe" formula mapping a dish → its ingredient with required quantity.

#### `RecipeItem` (app/models/recipe_item.rb) — continued
- **Class method:** `for_item(food_id:, variant_id: nil)` — returns variant recipe rows if `variant_id` present; otherwise base (no-variant) recipe rows. Used by `OrderItem.consumption_recipe_items` and `StockService.consume_order_item!`.
- **Custom validation:** `variant_belongs_to_food` — variant must belong to the same food.
- **Purpose:** The "recipe" formula mapping a dish → its constituent ingredients with required quantities.

### 5.2 Ordering & Payments

#### `Order` (app/models/order.rb)
- **Associations:** `belongs_to :table` (required), `belongs_to :waiter` (User, optional via `user_id`), `belongs_to :reservation` (optional), `has_many :payments` (dependent destroy), `belongs_to :promotion` (optional), `has_many :order_items` (dependent destroy + nested attributes with `reject_if: :order_item_dropped?`).
- **Enums:** `status: preorder(0)/inserve(1)/completed(2)`, default `inserve`.
- **Callbacks:**
  - `before_validation :set_table_price` — sets `table_price = table.table_type.price_add_on` if empty.
  - `after_create :sync_table!` — sets table status to occupied (inserve order) or reserved (preorder).
  - `after_update :sync_table!` — only when `saved_change_to_status?`.
  - `after_update :sync_reservation` — when order completed, marks reservation `completed`.
  - `after_save :recalculate_total_price!` — only when `table_price_changed? || order_items.any?`.
- **Scopes:** `unreleased_preorders`, `released_preorders`, `dining_history_for(user)` — LEFT JOINs reservations + orders for a customer, includes walk-ins, returns completed orders ordered by updated_at desc.
- **Instance methods:**
  - `completed_payment(loaded_payments = payments)` — most recent completed Payment.
  - `set_table_price` — computes table fee from table's table_type.
  - `recalculate_total_price!` — subtotal = table_price + Σ(unit_price × quantity); applies `membership_discount_amount`; floors at 0, 2 decimals; uses `update_columns` if persisted.
  - `sync_table!` / `sync_reservation` — see above.
  - `customer` — `reservation&.user || (waiter if waiter&.customer?)`.
  - `membership_discount_percent` — `customer&.current_member_tier&.discount` (integer %).
  - `membership_discount_amount(base = subtotal)` — `(base × percent / 100).round(2)`.
  - `release_time` — reservation.slot_start minus 10 minutes (nil-safe).
  - `due_for_release?(now)` — preorder AND no release time AND release_time ≤ now.
  - `release_to_kitchen!` — one-shot, safe on repeat calls; sets `released_to_kitchen_at`.
  - `schedule_kitchen_release` — if due, release now; else schedule `PreorderReleaseJob.perform_later(id)`.
  - `order_item_dropped?(attributes)` — private: true if food_id blank AND _destroy not "1".
- **Purpose:** Central order record. Links table, waiter, reservation, promotion, payments, and order items.

#### `OrderItem` (app/models/order_item.rb)
- **Associations:** `belongs_to :order` (touch: true), `belongs_to :food`, `belongs_to :food_variant` (optional).
- **Enums:** `status: pending(0)/accepted(1)/preparing(2)/ready(3)/served(4)/cancelled(5)`, default `pending`.
- **Callbacks:**
  - `before_validation :assign_unit_price` — unit_price = base_price + variant adjustment.
  - `after_save`/`after_destroy` :recalculate_order_total → calls `order.recalculate_total_price!`.
  - `after_update :auto_consume_stock` — if status change && accepted → deduct ingredients.
  - `after_update :restore_stock` — if cancelled && previously not pending → restore ingredients.
- **Constants:** `IN_KITCHEN_STATUSES = %i[pending accepted preparing]`.
- **Scopes:** `in_kitchen` — joins orders; lists kitchen-state items for non-preorder orders OR released orders, sorted by release time.
- **Instance methods:** `assign_unit_price`, `consumption_recipe_items`, `auto_consume_stock`, `restore_stock`, `ingredients_in_stock` (validates on create), `food_variant_belongs_to_food`.
- **Purpose:** Line item tracker with its own status machine + auto stock management.

#### `Payment` (app/models/payment.rb)
- **Associations:** `belongs_to :order`, `belongs_to :payment_method`, `belongs_to :processed_by` (User, optional).
- **Enums:** `status: pending(0)/completed(1)/failed(2)/refunded(3)`.
- **Callbacks:** `after_update :credit_customer_year_spend` — when status → completed: increments customer's `year_spend`.
- **Validations:** `subtotal`, `discount_amount`, `total_amount` ≥ 0; `total_amount` > 0; `currency` present.
- **Custom methods:** `vietqr_url` (if method is QR → `VietqrUrlBuilder.call(self)`); `total_amount_vnd` (USD→VND conversion); `paid_at_or_created`.
- **Purpose:** Payment transaction record; links to Stripe checkout session; VietQR support.

#### `PaymentMethod` (app/models/payment_method.rb)
- **Associations:** `has_many :payments` (restrict_with_error).
- **Enums:** `code: cash(0)/card(1)/qr(2)`.
- **Purpose:** Supports three payment types; `qr?` indicates VietQR support.

#### `Review` (app/models/review.rb)
- **Associations:** `belongs_to :reservation`, `belongs_to :customer` (User via `user_id`, optional), `has_one_attached :image`.
- **Callbacks:** `before_validation :assign_customer` on create — sets `user_id ||= reservation.user_id`.
- **Validations:** `rating` integer 1–5; `comment` ≤ 1000; `customer_must_match_reservation`; `reservation_must_be_reviewable` (on create); `one_review_per_customer`.
- **Scopes:** `recent` (desc), `visible` (includes customer + reservation, table, user), `for_customer(customer)`, `average_rating(scope = nil)`.
- **Instance methods:** `reviewer`, `reviewer_name`, `table`, `meal_at`, `meal_label`.
- **Purpose:** One review per customer per restaurant; validated against reservation reviewability.

### 5.3 Reservations & Seating

#### `Reservation` (app/models/reservation.rb)
- **Associations:** `belongs_to :user` (optional), `belongs_to :table`, `has_many :reviews` (destroy), `has_many :orders` (destroy).
- **Constants:** `MEAL_DURATION = 2.hours`; `MEAL_START_HOURS = [11, 13, 17, 19, 21]`.
- **Enums:** `status: pending(0)/approved(1)/rejected(2)/checked_in(3)/cancelled(4)/completed(5)`, default `pending`.
- **Public constants:** `ACTIVE_STATUSES = %i[pending approved checked_in]` — reservations that "hold a table".
- **Callbacks:** `after_create` / `after_update` / `after_destroy :sync_table_status`; `after_update :enqueue_confirmation_email` (when status → approved); `after_update :start_service_for_preorders` (when checked_in).
- **Validations:** `table_must_not_be_double_booked` (range overlap in same day), `table_must_be_bookable` (not out_of_service, not occupied same date), `reservation_time_must_be_a_meal_slot` (X:00 where X ∈ MEAL_START_HOURS).
- **Instance methods:** `slot_start`, `slot_end` (2h later), `holds_table_now?(time)`, `meal_slots_for(date)` static, `available_slots(table, date, exclude_id:)` static, `reviewable?` (not blocked, has user, and (completed? || past `slot_end`)), `reviewable_by?(customer)`, `review` (memoized), `reviewable_for(user)` static, `start_service_for_preorders` (marks each preorder order inserve + releases to kitchen), `sync_table_status` (delegates to `table.refresh_status_from_reservations!`), `enqueue_confirmation_email` (`ReservationConfirmationJob.perform_later(id)`).
- **Purpose:** Core booking model. Meal duration (2h) + start hours [11,13,17,19,21] define the booking calendar. Uses half-open intervals `[start, end)` for range overlap.

#### `CustomerQueue` (app/models/customer_queue.rb)
- **Associations:** `belongs_to :user` (optional), `belongs_to :table` (optional).
- **Enums:** `status: waiting(0)/seated(1)/cancelled(2)`.
- **Scopes:** `waiting` (status = waiting, ordered by created_at ASC).
- **Validations:** `guest_name` presence; `guest_phone` (9–11 digits) presence + format.
- **Instance methods:** `hold_table!(table)` — sets status seated + assigns table; `cancel!` — sets status cancelled.
- **Purpose:** Live queue management for walk-ins.

### 5.4 Inventory & Stock

#### `StockTransaction` (app/models/stock_transaction.rb)
- **Associations:** `belongs_to :ingredient`, `belongs_to :user` (optional).
- **Enums:** `transaction_type: stock_in(0)/stock_out(1)/adjustment(2)/waste(3)`.
- **Scopes:** `recent` (desc), `by_ingredient`, `by_type`, `between` (from/to).
- **Validations:** `quantity` > 0 unless adjustment; quantity > 0 (nonzero) if adjustment.
- **Callbacks:** `before_validation :fill_quantities` — sets quantity_before/quantity_after from current ingredient quantity.
- **Computed:** `signed_quantity` — +qty for stock_in, −qty for stock_out/waste, +qty for adjustment.
- **Purpose:** Immutable audit log of every stock movement.

#### `RestockTask` (app/models/restock_task.rb)
- **Associations:** `belongs_to :ingredient`, `belongs_to :low_stock_request` (optional), `belongs_to :waste_report` (optional).
- **Enums:** `status: pending(0)/in_progress(1)/completed(2)/cancelled(3)`; `source: auto(0)/request(1)/waste(2)`.
- **Scopes:** `open` (pending or in_progress), `recent`, `by_status`.
- **Validations:** `quantity` > 0; `source_reference_consistency` — request source requires low_stock_request; waste source requires waste_report.
- **Instance method:** `complete!` — sets status to completed.
- **Purpose:** Tracks a replenishment task.

#### `LowStockRequest` (app/models/low_stock_request.rb)
- **Associations:** `belongs_to :user`, `belongs_to :ingredient`, `belongs_to :reviewed_by` (User, optional).
- **Enums:** `status: pending(0)/approved(1)/rejected(2)/completed(3)`; `urgency: low(0)/normal(1)/high(2)`.
- **Scopes:** `recent`, `open` (pending or approved), `by_status`, `by_urgency`.
- **Validations:** `note` ≤ 500 chars; `requester_must_be_kitchen_staff` — user must be kitchen_staff or admin.
- **Constants:** `REVIEW_TRANSITIONS` — `pending → [approved, rejected]`, `rejected → [approved]`, `approved → [completed]`.
- **Instance methods:** `review!(reviewer, decision, note:)` — validates transition chain, sets status/reviewed_by/reviewed_at/review_note, if approved → `create_restock_task!` (which links or creates a RestockTask with source `:request`). `mark_completed!` — sets status completed. `suggested_restock_quantity` → ingredient.suggested_reorder_quantity.
- **Purpose:** Expense-request flow: kitchen staff request more of an ingredient; inventory manager approves, which auto-creates a restock task.

#### `WasteReport` (app/models/waste_report.rb)
- **Associations:** `belongs_to :ingredient`, `belongs_to :user` (optional), `belongs_to :reviewed_by` (User, optional).
- **Enums:** `status: pending(0)/approved(1)/rejected(2)`.
- **Scopes:** `recent`, `by_status`.
- **Validations:** `quantity` > 0; `verified_quantity` ≥ 0 (nullable); `reason` ≤ 500.
- **Custom validation:** `verified_quantity_not_over_reported` — verified ≤ quantity.
- **Instance methods:** `review!(reviewer, decision, verified_quantity: nil, note: nil, create_restock_task: false)` — raises `ArgumentError` for invalid decision or if already reviewed; if rejecting requires a note; wraps in a transaction: sets status/reviewed_at/verified_quantity/review_note; if approved: calls `apply_waste_to_stock!` (`StockService.waste`) then optionally `create_waste_restock_task!` (creates a restock task with source `:waste` if none open).
- **Purpose:** Wastage tracking; approving triggers stock deduction + optionally restock.

#### `Table` (app/models/table.rb)
- **Associations:** `belongs_to :area`, `belongs_to :table_type`, `has_many :reservations` (destroy), `has_many :orders` (destroy), `has_many :customer_queues` (destroy).
- **Enums:** `shape: square(0)/round(1)/rectangle(2)`; `status: available(0)/occupied(1)/reserved(2)/out_of_service(3)`.
- **Constants:** `ALLOWED_CAPACITIES = [2,4,6,8,10]`; `SHAPE_CAPACITIES = { square: [2,4], round: [4,6], rectangle: [6,8,10] }`.
- **Callbacks:** `after_update :seat_waiting_guests` — when status → available → next waiting guest seated at this table.
- **Validations:** `table_number` presence + unique within area; `capacity` ∈ [2,4,6,8,10]; `shape` present; `capacity_matches_shape`; `radius` required for round (>0); width/height for non-round; coordinates numeric.
- **Callbacks:** `before_validation :generate_table_number` on create — generates number like `A3` from area + table_type initials + index.
- **Instance methods:** `refresh_status_from_reservations!` — recompute status:
  - If any reservation checked_in OR any order inserve → `:occupied` (guests physically stay seated).
  - Else ACTIVE reservations holding table now: if any checked_in → occupied; else if any → reserved; else → available.
  - `seat_waiting_guests` — delegates to `CustomerQueueManager.assign_next_available!(self)`.
- **Purpose:** Physical table registry for floor map, reservations, queue seating.

#### `TableType` (app/models/table_type.rb)
- **Associations:** `has_many :table` (destroy).
- **Validations:** `type` present; `price_add_on` present (fee added to order's total for tables of this type).
- **Note:** `self.inheritance_column = nil` — plain table, not STI.
- **Purpose:** Table categories with base price add-on.

#### `Area` (app/models/area.rb)
- **Associations:** `has_one_attached :image` (destroy_later), `has_many :tables` (destroy).
- **Enums:** `area_type: indoor(0)/outdoor(1)`.
- **Validations:** `name` present; `floor_level` present; `image_format` (PNG/JPEG/WebP/JPG < 5MB).
- **Purpose:** Physical grouping of tables (rooms/floors).

### 5.5 Users & Loyalty

#### `User` (app/models/user.rb)
- **Inheritance:** Devise model (database_authenticatable, registerable, recoverable, rememberable, validatable, `jwt_authenticatable`), `jwt_revocation_strategy: JwtDenylist`.
- **Associations:** `belongs_to :member_tier` (optional), `has_one_attached :avatar`, `has_many :reservations` (destroy), `has_many :notifications` (foreign_key recipient_id, destroy), `has_many :stock_transactions` (nullify), `has_many :waste_reports` (nullify).
- **Enums:** `role: admin(0)/inventory_manager(1)/kitchen_staff(2)/receptionist(3)/waiter(4)/customer(5)`.
- **Validations:** `full_name` presence; `email` presence + unique + email format; `phone` 9–11 digits + unique; `member_tier_id` integer; `year_spend` ≥ 0.
- **Attributes:** `year_spend` default 0.
- **Callbacks:** `after_save :calculate_member_tier!` (if `saved_change_to_year_spend?`); uses `after_save` (not after_update) so it fires on INSERT too. `before_validation :set_jti` on create (sets JWT id to secure random UUID).
- **Instance methods:** `current_member_tier` — returns `member_tier` or cheapest active tier; `next_member_tier` — next higher `active_price`; `amount_to_next_member_tier` — `max(next.active_price − year_spend, 0)` or nil; `calculate_member_tier!` — finds tier with `active_price <= spend` (desc order), updates `member_tier_id` via `update_column` (bypasses callbacks).
- **Purpose:** Identity for staff/customers; `role` drives authorization filters.

#### `MemberTier` (app/models/member_tier.rb)
- **Associations:** `has_many :users` (destroy).
- **Validations:** `discount` present; `active_price` present.
- **Purpose:** Loyalty tiers defined by `active_price` (spend threshold) and `discount` (percentage discount).

#### `JwtDenylist` (app/models/jwt_denylist.rb)
- `< ApplicationRecord` + `include Devise::JWT::RevocationStrategies::Denylist`.
- Stores revoked JWT `jti`s to prevent token reuse.

#### `Notification` (app/models/notification.rb)
- **Associations:** `belongs_to :recipient` (User).
- **Enums:** `status: unread(0)/read(1)`.
- **Scopes:** `recent` (desc), `by_status`, `search` (ILIKE on title/body).
- **Validations:** `redirect_url` must match URL or path pattern (deep-linking).
- **Callbacks:** `after_create_commit :broadcast_new_notification` — pushes Turbo Stream fragments to recipient's Action Cable stream.
- **Class methods:** `notify_role(role, title:, body:, redirect_url:, exclude:)` — creates notifications for all users with a given role.
- **Purpose:** All in-app notifications; real-time via Turbo Streams + Action Cable.

#### `Promotion` (app/models/promotion.rb)
- **Associations:** `has_one_attached :image`; `has_many :orders`.
- **Enums:** `discount_type: percentage(true)/fix_amount(false)`; `status: published(0)/cancelled(1)`.
- **Validations:** `name` presence; `discount_value` ≥ 0; `start_date`/`end_date` present; `dates_valid` (end > start); `image_type_and_size`.
- **Purpose:** Optional order-level discount promotion.

#### `Table` (app/models/table.rb)
- **Associations:** `belongs_to :area`, `belongs_to :table_type`, `has_many :reservations` (destroy), `has_many :orders` (destroy), `has_many :customer_queues` (destroy).
- **Enums:** `shape: square(0)/round(1)/rectangle(2)`; `status: available(0)/occupied(1)/reserved(2)/out_of_service(3)`.
- **Constants:** `ALLOWED_CAPACITIES = [2,4,6,8,10]`; `SHAPE_CAPACITIES = { square: [2,4], round: [4,6], rectangle: [6,8,10] }`.
- **Callbacks:** `after_update :seat_waiting_guests` — when status → available → next waiting guest seated.
- **Validations:** `table_number` presence + unique within area; `capacity` ∈ [2,4,6,8,10]; `shape`; `capacity_matches_shape`; `radius` required for round (>0); width/height for non-round; coordinates numeric.
- **Callbacks:** `before_validation :generate_table_number` — generates `A3`-style number from area + table_type initials.
- **Instance methods:** `refresh_status_from_reservations!` — recompute status:
  - If any checked-in reservation OR inserve order → occupied (guests physically seated).
  - Else ACTIVE reservations holding table now: checked_in → occupied; any → reserved; else → available.
  - `seat_waiting_guests` → delegates to `CustomerQueueManager.assign_next_available!`.
- **Purpose:** Physical table registry for floor map, reservations, queue seating.

#### `TableType` (app/models/table_type.rb)
- **Associations:** `has_many :table` (destroy).
- **Validations:** `type` present; `price_add_on` present (added to order total).
- **Note:** `self.inheritance_column = nil` — plain table, not STI.
- **Purpose:** Table categories with price add-on.

#### `Area` (app/models/area.rb)
- **Associations:** `has_one_attached :image` (purge_later), `has_many :tables` (destroy).
- **Enums:** `area_type: indoor(0)/outdoor(1)`.
- **Validations:** `name`; `floor_level`; `image_format` (PNG/JPEG/WebP/JPG < 5MB).
- **Purpose:** Physical grouping of tables.

### 5.5 Users & Loyalty

#### `User` (app/models/user.rb)
- **Devise model** + `jwt_authenticatable` + `jwt_revocation_strategy: JwtDenylist`.
- **Associations:** `belongs_to :member_tier` (optional); `has_one_attached :avatar`; `has_many :reservations` (destroy); `has_many :notifications` (recipient_id, destroy); `has_many :stock_transactions` (nullify); `has_many :waste_reports` (nullify).
- **Enums:** `role: admin(0)/inventory_manager(1)/kitchen_staff(2)/receptionist(3)/waiter(4)/customer(5)`.
- **Validations:** `full_name`; `email` + unique + format; `phone` 9–11 + unique; `member_tier_id` integer; `year_spend` ≥ 0.
- **Callbacks:** `after_save :calculate_member_tier!` (if changed); `before_validation :set_jti` on create.
- **Instance methods:** `current_member_tier`; `next_member_tier`; `amount_to_next_member_tier`; `calculate_member_tier!` — finds tier where `active_price <= year_spend` and updates `member_tier_id` via `update_column`.
- **Purpose:** Identity model; `role` drives authorization.

#### `MemberTier` (app/models/member_tier.rb)
- `has_many :users` (destroy); `discount` + `active_price` required.
- Loyalty tiers: `active_price` = spend threshold, `discount` = percentage discount.

#### `JwtDenylist` (app/models/jwt_denylist.rb)
- `include Devise::JWT::RevocationStrategies::Denylist`; revokes JWT tokens by `jti`.

#### `Notification` (app/models/notification.rb)
- `belongs_to :recipient` (User); `status: unread(0)/read(1)`.
- **Scopes:** `recent`, `by_status`, `search` (ILIKE title/body).
- `after_create_commit :broadcast_new_notification` — Turbo Stream push to Action Cable.
- `self.notify_role(role, title:, body:, redirect_url:, exclude:)` — broadcast to all users with a role.
- **Purpose:** In-app notifications + real-time push.

#### `Promotion` (app/models/promotion.rb)
- `has_one_attached :image`; `has_many :orders`.
- `discount_type: percentage(true)/fix_amount(false)`; `status: published(0)/cancelled(1)`.
- `dates_valid` → end_date > start_date.
- **Purpose:** Order-level discount promotion.

---

## 6. Controllers (grouped by domain)

### 6.1 ApplicationController (55 lines)
- **Includes:** Pundit.
- **Callbacks:** `configure_permitted_parameters` (devise sign_up/account_update: adds full_name, phone, location, avatar).
- **Layout:** `layout_by_resource` → always `application`.
- **Authorization rescue:** `rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized` → HTML 403 + JSON error.
- **`after_sign_in_path_for(resource)`** → `root_path` for all (role split elsewhere).
- **Protected helpers:**
  - `notify_user(recipient:, title:, body:, redirect_url:)` — creates a `Notification` record.
  - `notify_role(role, title:, body:, redirect_url:, exclude:)` — bulk notification helper (delegates to `Notification.notify_role`).

### 6.2 DashboardsController (64 lines)
- **Namespace:** none. `before_action :authenticate_user!`.
- **Actions:**
  - `index` (admin/dashboards/index): date range (`@from_date..@to_date`); `RestaurantPerformanceService` with `time_range`; open reservations list (not completed/rejected/cancelled; 5/page); renders admin dashboard.
  - `performance` (admin/dashboards/performance): same date range; `@performance` = full `Service.call` result; renders performance view.
- **Private:** `resolve_range` — defaults to last 30 days; ISO8601 parse; fallback on `ArgumentError`.

### 6.3 OrdersController (150 lines)
- `before_action :set_order` (params require).
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `index` | Orders list; filters by `params[:status]`, `params[:table_id]`, `params[:date]`; loads `@tables`. |
  | `show` | Order detail; builds empty order item form; loads payment methods + food data. |
  | `new` | Pre-orders start here; loads booked tables. |
  | `create` | Creates order; `waiter = current_user`; status `:inserve` for staff, `:preorder` for customer; links existing reservation for table; notifies kitchen_staff; redirects. |
  | `update` | Updates params; `recalculate_total_price!` after update; `see_other` redirect. |
  | `update_status` | Status transition; blocks `completed` unless at least one completed payment exists; recalculates total. |
  | `destroy` | Destroys order (cascade: items, payments, etc.). |
- **Private:** `set_order`; `load_booked_tables` (reservations today + occupied tables); `current_reservation_for(table)`; `load_food_data` (categories, foods, `variants_by_food` grouped map); `order_status_for(user)` — customer? `:preorder` : `:inserve`; `order_params` (nested order_items attrs); `order_status_params`.

### 6.4 OrderItemsController (82 lines)
- `before_action :set_order_item`.
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `create` | Adds item to existing order; notifies kitchen_staff on success. |
  | `update_status` | **Order item state machine:** validates against `OrdersHelper::ORDER_ITEM_TRANSITIONS`; waiters restricted to pending→cancelled, ready→served; success → notify waiters when item becomes `served?`; rescues `StockService::InsufficientStock`. |
  | `destroy` | Removes item; redirects to order/index. |
- **Private:** `set_order_item`, `order_item_params`.

### 6.5 BillsController (30 lines)
- `before_action`: authenticate, set_order, set_payment.
- `show` — authorizes order; shows order items; responds HTML + PDF (`InvoicePdf.new(order:, payment:).generate`).

### 6.6 PreordersController (93 lines)
- `before_action :set_order`.
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `index` | Staff overview: all preorder orders (with reservation, table, items) ordered desc. |
  | `new` | Customer dish-picking screen after table booking; pre-fills order `status: preorder` + `reservation_id`. |
  | `create` | Creates order `status: preorder`; links to reservation's table; `schedule_kitchen_release`; notifies kitchen_staff. |
  | `show` | Pre-order detail + total. |
  | `release` | Manual instant kitchen release; notifies kitchen_staff. |
  | `destroy` | Cancels pre-order. |

### 6.7 PaymentsController (130 lines)
- `before_action`: set_order, set_payment.
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `create` | Creates pending payment. Guards: reject if order completed; reject if pending payment exists; recalc total; find active payment method. Card → Stripe Checkout session (stores session id). QR → redirect to bill page (VietQR). Handles `RecordNotFound` (method unavailable) + `Stripe::StripeError` (mark failed). |
  | `confirm` | **Payment confirmation:** pending only; recalc total == payment total; in transaction: payment completed + order completed. |
  | `success` | Stripe callback: retrieve session; if `payment_status == paid` → complete payment + order (transaction); else redirect to bill. |

### 6.8 ReservationsController (158 lines)
- `before_action`: authenticate_user! (except index); set_reservation.
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `index` | Public list; area filtering + prev/next navigation + tables payload for floor map. |
  | `new` | Booking form; defaults table_id param; computes date; sets available slots. |
  | `create` | Creates reservation; marks `user` if logged in; notifies receptionist + admin; redirects to `new_reservation_preorder_path` (dish-picking). |
  | `update` | Updates; reschedules kitchen release for linked preorder orders (`T-10` follows updated `slot_start`). |
  | `update_status` | Staff-only status change (approve/reject/check-in); notifies customer via `notify_user`. |
  | `show` / `destroy` | Show detail / destroy. |
- **Private:** `set_reservation`; `set_schedule` (all meal slots + available slots for current table); `reservation_params` (excludes `status` — staff-only); `status_params`; `table_json` (for floor map JS).

### 6.9 ReviewsController (120 lines)
- `before_action`: authenticate_user! (except index/show); set_review.
- **Actions:**
  | Action | Purpose |
  |---|---|
  | `index` | Visible reviews, recent, 6/page; shows avg rating + count. |
  | `show` | Single review. |
  | `new` | Redirects to existing review if user already reviewed; else loads the reservation for review. |
  | `create` | Creates review; rescues `RecordNotUnique` (double-submit race); notifies admin. |
  | `restaurant` (collection route) | Redirects to customer's next reviewable reservation (post-visit). |
  | `update` | Updates rating/comment; attaches new image if present. |
  | `edit` / `destroy` | Edit form / remove review. |

### 6.10 NotificationsController (38 lines)
- `before_action`: authenticate_user!; `filter_notifications` (index only).
- `index` (filtered); `mark_read` (single); `mark_all_read` (collection).

### 6.11 PromotionsController (87 lines)
- Standard CRUD (index/show/new/create/edit/update/destroy); notification on each success.

### 6.12 MenusController (19 lines)
- `index`: all categories, foods, variants + restaurant reviews (latest 3 + count + avg rating).
- `show`: food detail + variants + recipe items.

### 6.13 FoodsController (89 lines)
- CRUD with notification on each success. `food_params`: category_id, name, description, base_price, status, image.

### 6.14 FoodVariantsController (126 lines)
- CRUD + search/filter/sort: `?q=` (searches food_variants.name OR foods.name OR categories.name ILIKE), `?food_id=`, sort by newest/oldest/name_asc/name_desc/price_asc/price_desc. Stats: total_variants, total_dishes (distinct food_id count), avg_adjustment.
- `food_variant_params`: food_id, name, price_adjustment.

### 6.15 IngredientsController (127 lines)
- CRUD + `deactivate`/`reactivate` (soft delete).
- **Create:** resets `current_quantity = 0`, then in a transaction: saves; if `initial_quantity > 0` → `StockService.restock`; then `StockService.sync_restock_task!`.
- **Update:** calls `sync_restock_task!` after update.
- `create_params`: category, name, unit, unit_cost, low_stock_threshold, reorder_quantity, initial_quantity.

### 6.16 CategoriesController (127 lines)
- CRUD + analytics on index: dishes count per category (SQL subquery), total categories, total dishes, empty categories.
- `category_params`: name.

### 6.17 TablesController (146 lines)
- CRUD; `index` renders `tables/index` (floor map) with: `@areas`, `@area` (resolved), `@prev_area`/`@next_area` navigation, `@tables_payload` (JSON) for JS.
- `table_json(table)` — base payload + radius (round) or width/height (non-round).
- `tables_by_area` — area id → list of table payloads (for canvas).
- `table_params` — all geometry + meta fields.

### 6.18 TableTypesController (70 lines)
- CRUD with JSON responses for create/update (embedded `respond_to`). `table_type_params`: type, price_add_on.

### 6.19 AreasController (71 lines)
- CRUD for areas; `area_params`: area_type, name, floor_level, image.
- `destroy` rescues `ActiveRecord::RecordNotDestroyed` → descriptive error.

### 6.20 UsersController (105 lines)
- `index` → renders admin staff list (`admin/users/index` template).
- `show`: profile + member tier info + dining history + reservations (3/page each, separate pagination).
- `create`/`update`: admin-only fields (`role`, `status`, `member_tier_id`, `year_spend`) only for admins.
- `user_params`: full_name, email, phone, location, avatar (+ admin extras).

### 6.21 Users::SessionsController (25 lines)
- Overrides `create`/`destroy` to return JSON user payload on login/logout.

### 6.22 Users::RegistrationsController (37 lines)
- Devise registration overrides; custom parameters (full_name, phone, location, avatar).

### 6.23 Kitchen::DashboardsController (8 lines)
- `index`: shows my low stock requests + my waste reports.

### 6.24 Kitchen::LowStockRequestsController (42 lines)
- `index` (all open), `show`, `new` (ingredient list), `create` (with `user: current_user`; notifies inventory_manager + admin).

### 6.25 Kitchen::WasteReportsController (41 lines)
- `index`/`show`/`new` (ingredients list)/`create` (with user: current_user).

### 6.26 Inventory::DashboardsController (18 lines)
- `index`: needs_restock ingredients, open restock tasks, pending low-stock requests, pending waste reports + summary hash.

### 6.27 Inventory::StockTransactionsController (25 lines)
- `index` (filtered by ingredient/type/date range; 15/page), `show`.

### 6.28 Inventory::RestockTasksController (84 lines)
- `index` (by status), `show`, `refill` (GET page), `complete` (PATCH):
  - Updates task status/received_quantity/supplier/note/completed_at.
  - Calls `StockService.restock` for the ingredient.
  - Marks approved low-stock requests as completed.
  - Notifies owner + all (except current user).
  - Rescues `StockService::Error`.

### 6.29 Inventory::LowStockRequestsController (37 lines)
- `index` (by status), `show`, `review` (PATCH to `LowStockRequest#review!`) → notifies requester.

### 6.30 Inventory::ReportsController (172 lines)
- `index`: the inventory dashboard/report page.
- Loads: `stock_transactions` (filtered by ingredient/type/date; 15/page), `@stock_ins`/`@stock_outs`.
- Builds summaries via raw SQL: `build_report_summary` (total ingredients, stock value, low_stock, out_of_stock); `build_restock_summary` (total/completed/pending/expected/received qty).
- `build_ingredient_movements`: per-ingredient received/issued/wasted totals in period; `average_daily_issue` + `days_left` forecast.
- Pagination: 10 ingredients, 10 restock tasks, 15 transactions.
- Date range: default 30 days; max 366 days.

### 6.31 Inventory::WasteReportsController (43 lines)
- `index`/`show`/`verify` (PATCH to `WasteReport#review!`) → notifies reporter.

### 6.32 Admin::ReservationsController (71 lines)
- `index` (staff list).
- `update_status` → approve/reject/check-in; all linked preorder orders → `schedule_kitchen_release`.
- `assign_table` → change table, set status `approved`, reschedule, refresh old table.
- `change_table` → move reservation to different table (keep status).

### 6.33 Admin::CustomerQueuesController (52 lines)
- `index` (queue + available tables); `create` → `CustomerQueueManager.enqueue_walk_in!`; `seat` → `CustomerQueueManager.seat!` (creates inserve order); `cancel` → `cancel!`; `destroy` (hard delete).

### 6.34 Admin::KitchenQueuesController (97 lines)
- `index`: kitchen items (hidden behind Pundit policy); `show`: full order + recipe map + ingredient aggregation (low-stock flags).
- `update_status`: order item state machine + transition validation; notifies waiters when item `served?`; catches `StockService::InsufficientStock`.

---

## 7. Services (6 files)

### 7.1 StockService (125 lines)
Modular service for all stock arithmetic. All methods are class-level.

| Method | Purpose |
|---|---|
| `apply_transaction(ingredient:, transaction_type:, quantity:, user:, reason:, reference:, strict:)` | Core: computes delta (`stock_in`→+, `stock_out`/`waste`→−, `adjustment`→±); raises `InsufficientStock` if negative (strict); in DB transaction: locks ingredient row (`Ingredient.lock.find`), computes before/after, creates `StockTransaction`, updates `current_quantity`, calls `sync_restock_task!` if low/out. |
| `restock(...)` | Convenience: `apply_transaction(..., transaction_type: :stock_in, ...)` |
| `waste(...)` | Convenience: `apply_transaction(..., transaction_type: :waste, ...)` |
| `adjust(ingredient:, new_quantity:, user:, reason:)` | delta = new_quantity − current; >0 → stock_in, <0 → stock_out; no-op if unchanged. |
| `consume_order_item!(order_item, user:)` | For each recipe item of the order item: deduct `ingredient` by `recipe.quantity_required × order_item.quantity` (strict). Skips cancelled items/missing ingredients. Checks duplicate reference via `StockTransaction.exists?`. |
| `consume_order!(order, user:)` | Runs `consume_order_item!` for all non-cancelled items. |
| `restore_order_item!(order_item, user:)` | Reverses a cancelled item: finds all `stock_out` transactions by this reference and re-enters as `stock_in` with restore reference key. |
| `sync_restock_task!(ingredient)` | If ingredient is `low_stock?`/`out_of_stock?` AND no open task → creates `RestockTask` (source `:auto`, qty = suggested_reorder_quantity); notifies `inventory_manager` + `admin` roles. |

**Exceptions:** `Error < StandardError` / `InsufficientStock < Error`.

### 7.2 StockAvailability (24 lines)
- **Struct:** `Shortage` (keyword_init: ingredient, needed, available) → `message` readable string.
- `shortages(food_id:, variant_id:, quantity:)` — which recipe ingredients are insufficient for given food (+variant+qty). Filters to `needed > available` (only active ingredients count).
- `unavailable_food_ids` — static; returns food_ids whose base (non-variant) recipe items have an ingredient that is inactive OR `current_quantity < quantity_required`.
- **Used by:** `OrderItem#ingredients_in_stock` (on creation) and order item form.

### 7.3 CustomerQueueManager (20 lines)
- `enqueue_walk_in!(attrs, staff:)` — creates waiting queue entry + staff.
- `seat!(queue_entry, table)` — transaction: mark seated + assign table; create inserve order.
- `assign_next_available!(table)` — if table available → seat first waiting guest.

### 7.4 VietqrUrlBuilder (42 lines)
- Static helper for VietQR.io QR image URL.
- `configured?` — bank_code, account_number, account_name must all be present (ENV or credentials `vietqr:`).
- `call(payment)` — query param with amount (VND), `addInfo: ORDER-#{order_id}-PAYMENT-#{payment_id}`, accountName; returns `https://img.vietqr.io/image/{bank_code}-{account_number}-compact2.jpg?{query}`.
- `exchange_rate` — ENV `USD_TO_VND_RATE`, else credential, else 25,000.
- `amount_in_vnd(payment)` → `total_amount × exchange_rate` (rounded).

### 7.5 InvoicePdf (214 lines)
- Subclass of `Prawn::Document`.
- `initialize(order:, payment:)` — A4 portrait, margin 40, sets up DejaVu fonts.
- `generate` → header, order information, items table, totals, footer.
- `add_items_table` — shows each order item (food + variant, qty, unit price, amount).
- `add_totals` — subtotal, discount (member %), total USD + VND; warning note if order total changed after payment was created.
- Helpers: `customer_name`, `table_label`, `waiter_name`, `payment_method_name`, `issued_at_label`, `paid_at_label`, `discount_label`, `item_name`, `format_vnd`, `format_usd`.

### 7.6 RestaurantPerformanceService (147 lines)
- Data engine for admin dashboard. Receives `from_date`, `to_date`, `time_range`.
- `overview` — returns lightweight hash of 6 key metrics: net_revenue, gross_profit, gross_margin, occupancy_rate, avg_rating, low_stock_count.
- `call` — full report with 9 sections: summary, revenue, costs, profit, operations, customer, inventory, reservation_funnel, daily_trend, monthly_trend.

| Section | Computation |
|---|---|
| revenue | gross (Σ subtotals in range), net (Σ completed payments), refund, by_payment_method |
| costs | cogs (Σ qty×unit_price of order items), waste (Σ verified_qty × unit_cost) |
| profit | net − cogs; margin = gross_profit/net × 100; after_waste = gross_profit − waste |
| operations | occupancy_rate (occupied/total), aov, order_status breakdown |
| customer | avg rating, reviews count, low rating (<=2) count |
| inventory | total stock value (Σ qty × unit_cost), low_stock_count, out_of_stock_count |
| reservation_funnel | pending/approved/checked_in/completed/cancelled counts |
| daily_trend / monthly_trend | payment totals by date / by month |

---

## 8. Jobs (3 files)

### 8.1 ApplicationJob (7 lines)
- Base for all jobs; `retry_on` and `discard_on` commented out.

### 8.2 PreorderReleaseJob (22 lines)
- **Queue:** `:default`; retry on `ActiveRecord::Deadlocked` (3 attempts, 5s wait).
- `perform(order_id)`:
  - Returns if order nil, already released, not preorder, no valid reservation, or due date not reached.
  - On success: `release_to_kitchen!` + for each kitchen_staff user → creates notification (title "Pre-order", body with guest name + table + meal start time).
- **Triggered by:** `Order#schedule_kitchen_release` (when release_time > now) AND by `PreorderReleaseSweepJob`.

### 8.3 PreorderReleaseSweepJob (11 lines)
- **Queue:** `:low`.
- `perform` — scans all `Order.unreleased_preorders` (preorders with nil `released_to_kitchen_at`), eager-loads reservation/table/items, batch 200; schedules `PreorderReleaseJob` for each `due_for_release?` order.
- **Scheduled via sidekiq-cron:** `cron: "* * * * *"` (every minute) in `config/sidekiq_cron.yml`.

### 8.4 ReservationConfirmationJob (11 lines)
- `perform(reservation_id)` — finds reservation; returns if not approved, nil user, or missing email; sends `ReservationMailer.confirmation(reservation).deliver_now`.
- **Triggered by:** `Reservation#after_update` callback when status → approved.

---

## 9. Mailers (2 files)

### 9.1 ApplicationMailer (4 lines)
- `default from: "from@example.com"`; layout `mailer`.

### 9.2 ReservationMailer (13 lines)
- `default from: ENV.fetch("GMAIL_USERNAME")` — sends via Gmail.
- `confirmation(reservation)` — sets @reservation/@user/@table; `mail(to: user.email, subject: "Reservation Table Successfully")`.
- **Triggered by:** `ReservationConfirmationJob` → sends email to customer.

---

## 10. Views (220 ERB templates)

Views follow standard Rails conventions plus custom namespaces matching controller namespaces:

```
app/views/
├── admin/tables/          # legacy admin table forms
├── categories/            # CRUD + JSON (jbuilder)
├── cates/                 # legacy alias folder; same CRUD as categories
├── foods/                 # CRUD + JSON
├── food_variants/         # CRUD + JSON; _search_bar, _variant_table, _variant_rows, _form_fields_*, _show_* partials
├── ingredients/           # CRUD + JSON
├── inventory/             # Dashboards, summary cards, restock/refill
├── kitchen/               # Low stock + waste reports index/new/show
├── orders/                # _food_select, _add_item_form, _item_row, _order, _form
├── payments/              # Payment build form + JSON
├── preorders/             # Customer dish-picking form
├── reservations/          # Booking form (_reservation, _form)
├── reviews/               # Review form
├── users/                 # Staff list (_dining_history_item), user CRUD
├── notifications/         # Notification list/_bell_badge/_notification/_notification_card
├── layouts/               # application.html.erb (header/flash/footer/sidebar), devise, mailer, story
├── home/                  # Static pages (index, careers, contact_us, our_story, privacy_policy, terms_of_service)
├── reservation_mailer/    # Confirmation email HTML + text
└── pwa/                   # manifest.json.erb + service-worker.js
```

### Key View Patterns
- **JSON views** (e.g., `foods/index.json.jbuilder`) — rendered on non-HTML requests for mobile/desktop clients.
- **Shared partials:** `_food`, `_food_variant`, `_category`, `_ingredient`, `_table`, `_table_type`, `_notification`, `_notification_card`, `_banner`, `_flash` (via layouts), `_sidebar` variants (admin/inventory/kitchen).
- **Turbo Streams** (`app/views/pwa/service-worker.js`) for live notifications.

---

## 11. Helpers (20 files)

All standard Rails helpers in `app/helpers/*.rb`. The most important:

- **`OrdersHelper`** — contains `ORDER_ITEM_TRANSITIONS` (state machine allowed transitions: pending → accepted → preparing → ready → served / → cancelled) and `WAITER_ALLOWED_TRANSITIONS` (waiters: pending → cancelled, ready → served). Used in `Admin::KitchenQueuesController#order_item_transition_allowed?` and `OrderItemsController#update_status`.

Other domain helpers: `ApplicationHelper`, `BillsHelper`, `CategoriesHelper`, `CatesHelper`, `FoodsHelper`, `FoodVariantsHelper`, `HomeHelper`, `IngredientsHelper`, `InventoryHelper`, `MenusHelper`, `NotificationsHelper`, `OrderItemsHelper`, `OrdersHelper`, `PaymentsHelper`, `PreordersHelper`, `PromotionsHelper`, `RecipeItemsHelper`, `ReservationsHelper`, `ReviewsHelper`, `TablesHelper`, `TableTypesHelper`, `UserHelper`, `UsersHelper`.

---

## 12. JavaScript (Stimulus controllers, 17 files)

| Controller | Purpose |
|---|---|
| `application.js` | Bootstraps Stimulus + imports all controllers via `index.js` |
| `category_form_controller.js` | Dynamic category filter for food forms |
| `dropdown_controller.js` | Generic dropdown toggle (search/filter bars) |
| `floor_map_controller.js` | Renders area floor map (Konva.js) + circle/rect table placement |
| `food_variant_form_controller.js` | Shows/hides variant selector in food form |
| `hello_controller.js` | Starter demo |
| `index.js` | Registers all controllers |
| `order_form_controller.js` | Live price/quantity updates on order form (unit price recalc) |
| `promo_slider_controller.js` | Promotion slider on the menu |
| `recipe_item_form_controller.js` | Recipe wizard (ingredient + quantity step) |
| `reservation_pick_controller.js` | Date/slot picker for reservations |
| `reservation_schedule_controller.js` | Dynamic available-slot highlighting |
| `star_rating_controller.js` | 5-star rating UI for reviews |
| `stock_adjustment_controller.js` | Inventory adjustment + restore UI interactions |
| `table_canvas_controller.js` | Drag-and-drop table placement on floor map (table editor) |
| `table_image.js` | Image attachments on tables |
| `table_wizard_controller.js` | Multi-step table creation (fixed-size / size-agnostic flow) |

**Tech:** Hotwire/Turbo + Stimulus + Konva.js (canvas) + Tailwind CSS.

---

## 13. Configuration & Initialization

### 13.1 routes.rb (170 lines)
- `inventory` namespace: dashboards#index; reports, stock_transactions (index/show), restock_tasks (index/show + member refill/complete), low_stock_requests (index/show + member review), waste_reports (index/show + member verify), stock_adjustments (new/create).
- `kitchen` namespace: dashboards#index; low_stock_requests (index/show/new/create); waste_reports (index/show/new/create).
- Key routes: `resources :orders` (member update_status, nested payments with bill/success/confirm); `resources :order_items` (create/destroy + member update_status); `resources :reservations` (member update_status, nested preorders new/create); `resources :preorders` (show/index/destroy + member release); `resources :notifications` (member mark_read, collection mark_all_read).
- `devise_for :users` with custom controllers (sessions/registrations/passwords) + custom path names (login, logout, register, forgot-password).
- `authenticated :user` → root to `home#index`.
- Admin-only: `admin/users`, `admin/dashboards`, `admin/dashboards/performance` + `namespace :admin` (reservations/customer_queues/kitchen_queues).
- Sidekiq web UI at `/sidekiq` (admin-only auth).

### 13.2 database.yml
- PostgreSQL 9.5+; `max_connections` = `RAILS_MAX_THREADS` (default 5).
- `development`: postgres/postgres. `test`: restaurant_management_test.
- `production`: 4 databases (primary, cache, queue, cable) on separate DBs with `migrations_paths`.

### 13.3 queue.yml, sidekiq.yml, sidekiq_cron.yml
- queue.yml: poller batch 500, workers 3 threads, process count from `JOB_CONCURRENCY` (default 1).
- sidekiq.yml: concurrency 5, timeout 25s; queues: critical(2) → default(1) → low(1).
- sidekiq_cron.yml: `preorder_release_sweep` — cron `* * * * *`, class `PreorderReleaseSweepJob`, queue `low`.

### 13.4 cable.yml
- Dev: `async`; Test: `test`; Prod: `solid_cable` with message retention 1 day.

### 13.5 importmap.rb
- Pins: `application`, `konva` (CDN), `@hotwired/turbo-rails`, `@hotwired/stimulus` (+loading), `pin_all_from` on `app/javascript/controllers` (auto-register all Stimulus controllers).

### 13.6 kaminari_config.rb
- Default per-page 25 (commented), max per page nil.

### 13.7 devise.rb
- JWT: secret = `secret_key_base`, dispatch on POST `/login`, revocation on DELETE `/logout`, expiration 24 hours.
- `responder.error_status = :unprocessable_content`, `redirect_status = :see_other`.

### 13.8 Seeds
- `db/seeds.rb` — basic app data (categories, foods, ingredients, member tiers, users, promotions, areas, tables).
- `db/seeds_inventory_demo.rb` — demo inventory dataset for testing.
- Run: `bin/rails db:seed` / `db:seed:inventory_demo`.

### 13.9 lib/tasks/inventory.rake
- Custom Rake tasks for inventory operations (restock management, stock adjustment, data refresh).

---

## 14. Key Business Workflows

### 14.1 Order Lifecycle (in-person)
1. Waiter creates an order on a booked/occupied table (`OrdersController#create`).
2. Order auto-sets `table_price = table_type.price_add_on`, status `:inserve`.
3. Kitchen notified via `notify_role(:kitchen_staff, ...)`.
4. Waiter adds items (`order_items#create`): each item gets unit_price = base + variant adjustment; validates ingredients in stock (`StockAvailability.shortages`).
5. When item transitions to `accepted` → `auto_consume_stock` → `StockService.consume_order_item!` deducts ingredient stock (strict), creates stock transactions.
6. Chef advances items on the `Admin::KitchenQueuesController` screen (state machine).
7. When order completed → wait for a completed payment → `PaymentsController#confirm` updates payment + order status `:completed`.
8. Order's `after_update :sync_reservation` marks linked reservation completed.

### 14.2 Pre-order Lifecycle (table booking → pre-order → kitchen)
1. Guest books a table (`ReservationsController#create`): validates meal slot + no double-booking + table bookable.
2. System sends the guest to `new_preorder` (dish-picking screen).
3. Guest selects dishes; order created with `status: preorder`, linked to the reservation.
4. `schedule_kitchen_release` is called: if release_time (slot_start − 10 min) has passed → release now; otherwise schedules `PreorderReleaseJob` for `wait_until: rt`.
5. At T-10, `PreorderReleaseJob` runs; creates kitchen notifications to all kitchen staff.
6. `PreorderReleaseSweepJob` (every minute) is the safety net: releases any overdue orders.
7. On reservation check-in, `start_service_for_preorders` marks the order inserve and releases to kitchen.

### 14.3 Stock Consumption / Reconciliation
1. When an order item is accepted → `auto_consume_stock` → `StockService.consume_order_item!` → for each recipe item: deduct `ingredient.current_quantity` (strict).
2. If stock insufficient → `StockService::InsufficientStock` is raised → the order item transition fails with alert.
3. If an item is cancelled (from accepted/preparing/ready) → `restore_stock` re-adds the exact quantities.
4. On ingredient creation: initial_quantity > 0 → stock_in transaction; then `sync_restock_task!` creates auto restock task if low/out.
5. When a restock task is completed (`Inventory::RestockTasksController#complete`): `StockService.restock` adds quantity, marks approved low-stock requests complete.

### 14.4 Waste & Replenishment
1. Kitchen reports waste → `Kitchen::WasteReportsController#create` → `WasteReport` record.
2. Inventory approves/rejects: `review!()`: approve → `StockService.waste` (deducts verified_quantity, creates stock_transactions type waste), optionally auto-creates restock task (source `:waste`).
3. Rejection requires a note, leaves stock untouched.
4. Auto `sync_restock_task!` also triggers restock task creation when stock goes low/out.
5. Kitchen/manager can also manually request stock via `LowStockRequestsController` (kitchen staff), approved → creates/restocks restock task (source `:request`).
6. Full inventory reporting: `Inventory::ReportsController` shows moves, restock completions, and stock valuation.

### 14.5 Payment & Loyalty
1. Guest selects payment method (cash/card/QR); for card: Stripe Checkout session created and redirected; for QR: VietQR URL returned (VND converted via exchange rate).
2. On success/confirm: payment marked completed, order completed, `credit_customer_year_spend` adds `total_amount` to customer's `year_spend`.
3. `User#calculate_member_tier!` (after_save on year_spend change) updates `member_tier_id` by finding the tier with `active_price <= year_spend` (highest tier).
4. `membership_discount_amount` on orders is computed from the customer's current tier discount, applied in `Order#recalculate_total_price!`.
5. `Promotion` (percentage/fixed) is joined to the order and can be used at payment time; but current implementation reads the discount from the membership tier.

### 14.6 Notifications & Real-time (Turbo Streams)
1. Controller calls `notify_user`/`notify_role` → creates `Notification` record.
2. `Notification#after_create_commit` → `broadcast_new_notification` → pushes `<turbo-stream>` fragments to each recipient's Action Cable stream (`user:<id>`).
3. Browser pages with `<%= turbo_stream_from current_user %>` update the notification list + bell badge live.

### 14.7 Floor Map & Seating
1. Areas → tables with geometry; `Table#refresh_status_from_reservations!` recalculates status.
2. Reservations hold tables in ACTIVE statuses; table status = occupied when checked-in or order in service; reserved when future reservations present; available otherwise.
3. When a table becomes available → `Table#seat_waiting_guests` → `CustomerQueueManager.assign_next_available!` seats the next waiting guest and creates an order.

### 14.8 Reviews
1. After a completed visit, customer can rate 1–5 + optional comment + image.
2. `Review#reservation_must_be_reviewable` ensures only completed or past-due reservations allow reviews.
3. `Review#one_review_per_customer` prevents multiple reviews per user.
4. Reviews are visible on the restaurant menu page (public), and admin sees new reviews via `notify_role(:admin, ...)`.

---

## 15. Authorization & Role Hierarchy

### 15.1 Roles (User enum)
| Role | Value | Capabilities |
|---|---|---|
| `admin` | 0 | Full access everywhere; manages staff, tier, promotions; sidekiq web UI |
| `inventory_manager` | 1 | Inventory & restock workflows + all read; receives notifications |
| `kitchen_staff` | 2 | Kitchen queue dispatch, waste reports, low stock requests |
| `receptionist` | 3 | Reservations (public + admin status/assign/change table), customer queues |
| `waiter` | 4 | Full POS (create/update orders, status transitions) but restricted item transitions |
| `customer` | 5 | Bookings, pre-orders, reviews, payments (their own reservations) |

### 15.2 Authorization layers
- **Controller layer:** `authorize <Model>, :action?` in every action.
- **Pundit policies:** `app/policies/*.policies.rb` (food, table_type, area, order, reservation, order_item, category, customer_queue, stock_transaction, ingredient, user, promotion, waste_report, restock_task, low_stock_request, order_item_policy, etc.).
- **Controller base classes:** `Inventory::BaseController` requires `admin?` or `inventory_manager?`; `Kitchen::BaseController` requires `admin?` or `kitchen_staff?`.
- **Model layer:** validations + enum state machine prevent invalid transitions (e.g., `Reservation#table_must_not_be_double_booked`).

---

## 16. Key Patterns & Conventions

1. **Controller inheritance:** `ApplicationController` → `BaseController` (namespaced) chains → resource controllers.
2. **Pundit everywhere:** `authorize` + `policy_scope` on all queries; policies live in `app/policies/`.
3. **Nested attributes with reject_if:** `Order#accepts_nested_attributes_for(:order_items, reject_if: :order_item_dropped?)` avoids empty order item records.
4. **Transactions for multi-step integrity:** stock events (`StockService.apply_transaction`), payment & order completion, waste review, queue seating.
5. **Scoped enums for status:** `enum name, { key: value }` syntax (newer Rails 8 style, string-keyed values).
6. **HTTP conventions:** success redirects use `status: :see_other` (303) after POST/PUT for Turbo; errors use `status: :unprocessable_entity` (422).
7. **JSON Jbuilder views** for API-ish payloads.
8. **UNIX-style config:** ENV variables + Rails credentials for secrets (`config/credentials.yml.enc`).
9. **Search with `sanitize_sql_like`:** in `FoodVariantsController` and `Ingredient#search` scope.
10. **Performance patterns:** raw SQL for summary queries (`Inventory::ReportsController#build_report_summary`), eager loading (`includes`), `find_each(batch_size: 200)` for bulk jobs.
11. **Memoization:** `Review#review` caches `@review` instance variable.
12. **Powerful routing:** nested resources, member actions, API endpoints.

---

## 17. Model Relationship Overview

```
User (receives notifications, processes payments, creates stock reports)
 ├─→ Reservation (→ orders, reviews)
 ├─→ Notification
 ├─→ StockTransaction (nullify)
 └─→ WasteReport (nullify)

Table ←→ Area, TableType (belongs_to)
Table → Reservation (one-to-many), Order (one-to-many), CustomerQueue (one-to-many)

Order ←→ Table (belongs_to), Reservation (optional), User (waiter), Promotion
Order → OrderItem (one-to-many), Payment (one-to-many)

Food ←→ Category (belongs_to)
Food → FoodVariant (one-to-many), RecipeItem (one-to-many), OrderItem (one-to-many)
FoodVariant → Food (belongs_to), RecipeItem, OrderItem
RecipeItem → Food, FoodVariant (optional), Ingredient

Ingredient → RecipeItem, Food (through), StockTransaction, RestockTask, LowStockRequest, WasteReport

Reservation → Order, Review
OrderItem → Order, Food, FoodVariant

StockTransaction ←→ Ingredient, User
RestockTask ←→ Ingredient, LowStockRequest (optional), WasteReport (optional)
LowStockRequest ←→ User, Ingredient, User (reviewed_by)
WasteReport ←→ Ingredient, User, User (reviewed_by)

Payment ←→ Order, PaymentMethod, User (processed_by)
PaymentMethod → Payment (one-to-many)

Review ←→ Reservation, User (customer)
Promotion ←→ Order

Notification ←→ User (recipient)
```

### Key relationships in words
- **Food → RecipeItem → Ingredient:** The recipe formula. Each dish has zero or more recipe items; each recipe item ties a food (optionally with a variant) to an ingredient at a required quantity.
- **Order → OrderItem → Ingredient:** When an order item is accepted, `StockService.consume_order_item!` walks the order item's recipe items and deducts the relevant ingredients. Cancellations revert the stock.
- **Order → Reservation:** For preorders, the order is linked to the reservation; the reservation's slot_start − 10 min determines the kitchen release time.
- **Ingredient → RestockTask / LowStockRequest / WasteReport:** Inventory items can be restocked automatically (on low/out stock), via manual low-stock request (kitchen staff → inventory manager), or via waste report (inventory approves → auto restock).
- **User → Notification:** All in-app notifications. The `notify_role` helper broadcasts to everyone with a given role.

---

## 18. Testing

- Test suite in `test/`:
  - `test/models/` — validates each model (26 test files).
  - `test/controllers/` — controller action tests (23 files).
  - `test/services/` — `stock_availability_test.rb`, `stock_service_test.rb`.
  - `test/mailers/` — empty (only `.keep`).
  - `test/views/` — `pagination_component_test.rb`.
- Run with: `bin/rails test` or `bin/rails test test/models/order_test.rb` (single file).
- Uses standard Rails `ActiveSupport::TestCase` style (no Minitest/Shoulda gems in Gemfile beyond defaults).

---

## 19. Environment & Deployment

- **Development:** `bin/dev` or `bin/rails server` (uses `async` cable adapter, in-process jobs).
- **Test:** `bin/rails test`.
- **Production:** Docker + Kamal deploy; `solid_queue`/`solid_cache`/`solid_cable` for background, cache, and Action Cable.
- **Secrets:** `config/master.key`, `config/credentials.yml.enc` (never commit).
- **Environment variables used:** `VIETQR_BANK_CODE`, `VIETQR_ACCOUNT_NUMBER`, `VIETQR_ACCOUNT_NAME`, `USD_TO_VND_RATE`, `GMAIL_USERNAME`, `RAILS_MAX_THREADS`, `JOB_CONCURRENCY`, DB connection variables.

---

## 20. Key Implementation Notes & Gotchas

1. **Order total recalculation:** `Order#recalculate_total_price!` uses `update_columns` when the order is persisted to avoid triggering `after_save`/`after_update` callbacks and creating infinite loops. Non-persisted orders set attributes directly.
2. **Stock consumption idempotency:** `StockService.consume_order_item!` checks `StockTransaction.exists?(reference: "order_item:#{order_item.id}", transaction_type: :stock_out)` to prevent double-deducting when an order item is processed multiple times.
3. **Stock restoration on cancellation:** `restore_stock` walks all `stock_out` transactions for the item's reference and re-adds them as `stock_in` with a separate restore reference key, preserving the original per-recipe-item transaction records.
4. **Preorder release is one-shot:** `Order#release_to_kitchen!` guards with `return false if released_to_kitchen_at.present?` and `return false unless reservation && Reservation::ACTIVE_STATUSES.include?(reservation.status.to_sym)` to prevent race conditions.
5. **Kitchen queue sort:** `OrderItem#in_kitchen` scope uses a `CASE` expression to sort released preorder items to the top, then by `released_to_kitchen_at` (oldest first), then by item creation time — this implements a priority/FCFS kitchen queue.
6. **Waste approval is atomic:** `WasteReport#review!` wraps approval + stock deduction + optional restock task creation in a DB transaction. If stock service fails, the report is left in `approved` status requiring manual cleanup.
7. **Tailwind + Hotwire:** The UI is conventional CSR-free; Turbo + Stimulus + Tailwind provide the interactivity. Konva.js is only used for the floor map.
8. **Wildcard Sidekiq queue:** `queue.yml` uses `queues: "*"` (all queues) - Sidekiq routes jobs to the configured queue priority (critical → default → low).
9. **Reservations are time-boxed:** MEAL_DURATION = 2h with MEAL_START_HOURS [11,13,17,19,21] defines the entire reservation calendar. No overlapping bookings are allowed for the same table on the same date.
10. **Restaurant operating as a restaurant + POS:** The single `Order` model serves both in-person ordering and pre-orders. Status `:preorder` vs `:inserve` distinguishes them; the same `Order#sync_table!` and `release_to_kitchen!` logic serves both flows.
