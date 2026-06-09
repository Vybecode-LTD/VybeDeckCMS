# CLAUDE.md — VybeDeck CMS

> New sessions read this first. Then read `HANDOFF.md` for current state and `ROADMAP.md` for planned work.
> Keep "Last Completed Task" and "Active Task" current at the end of every session.

---

## Project Snapshot

| Field | Value |
|-------|-------|
| Name | VybeDeck CMS |
| Repo | `C:\DEV\VybeDeck\vybedeck_cms` |
| Remote | `https://github.com/Vybecode-LTD/VybeDeckCMS.git` |
| Branch | `main` |
| Platform | Railway (PaaS, auto-deploy from main) |
| Stack | Rails 8.1, Ruby 3.4, PostgreSQL 17, Propshaft, Importmap, Minitest |
| Last commit | `56ab9a6` |

## Last Completed Task (2026-06-09)

**Phase 3.6 — Refunds & Admin Order Management** (commit `56ab9a6`):
- `OrderPolicy#refund?` = admin only (irreversible financial action).
- `Admin::OrdersController#refund` (POST /admin/orders/:id/refund): finds order, authorises, guards `paid?` status, calls `Stripe::Refund.create(payment_intent:)`, marks order `:refunded`; rescues `Stripe::StripeError` with flash alert, leaving order unchanged.
- Custom `app/views/admin/orders/show.html.erb`: renders "Issue Full Refund" button (admin + paid order only, with turbo_confirm dialog), "← All Orders" link, formatted `total_display` instead of raw `total_cents`, status pill badge.
- `Admin::RevenueController#show` (GET /admin/revenue): monthly stats via `DATE_TRUNC('month', created_at)` PostgreSQL GROUP BY (last 12 months + all-time totals by currency); Pundit gated via `RevenuePolicy`.
- `RevenuePolicy#show?` = editor or admin.
- `app/views/admin/revenue/show.html.erb`: all-time summary cards + monthly breakdown table with formatted money.
- Revenue nav link added to `app/views/admin/application/_navigation.html.erb` (editor/admin only).
- Routes: `member { post :refund }` on admin orders; `resource :revenue, only: :show, controller: :revenue` (explicit controller to avoid Rails auto-pluralisation to `RevenuesController`).
- `LineItemDashboard` created (was missing, caused `uninitialized constant` on order show).
- `StripeHelper#with_stripe_refund` added (same `define_singleton_method` pattern; supports `raises:` kwarg for error simulation).
- `test/integration/admin_refunds_test.rb`: 11 tests (auth levels, business guards, Stripe error, captured params, show page).
- `test/integration/admin_revenue_test.rb`: 9 tests (auth levels, content, exclusion of non-paid orders).
- Full suite: **418 runs, 1040 assertions, 0 failures**.

**Phase 3.5 — Digital Downloads** (commit `c727281`):
- `Product` gets `has_many_attached :download_files` — zero migrations needed (Active Storage).
- `User` gets `has_many :orders` — enables `user.orders.paid.joins(:line_items)` purchase check.
- `ProductPolicy#download?`: admins/editors always allowed; regular users need a paid `Order` containing the product via `LineItem`.
- `DownloadPolicy#index?`: any authenticated user (formality — `require_authentication` already gates it).
- `DownloadsController`: `index` (lists products from paid orders that have download files attached); `show` (looks up blob by `signed_id`, verifies product ownership via `ActiveStorage::Attachment`, authorises via `ProductPolicy#download?`, redirects to `rails_blob_path` — works for both disk and S3).
- Routes: `GET /account/downloads` (as `account_downloads`), `GET /account/downloads/:id` (as `account_download`).
- `app/views/downloads/index.html.erb`: product groups with per-file download buttons; empty-state CTA to shop.
- `ActiveStorageMultiField` Administrate field: overrides `permitted_attribute` to return `{ attr => [] }`; templates at `app/views/fields/active_storage_multi_field/` for show/form/index.
- `ProductDashboard` updated: `download_files: ActiveStorageMultiField` in `ATTRIBUTE_TYPES`, `SHOW_PAGE_ATTRIBUTES`, and `FORM_ATTRIBUTES`.
- 90 lines of downloads CSS: `.download-product-list`, `.download-product__header`, `.download-file-list`, `.download-file`, `.download-btn`, admin file-list helpers.
- 12 integration tests in `test/integration/downloads_test.rb`.
- Full suite: **398 runs, 986 assertions, 0 failures**.

**Phase 3.4 — Stripe Payment Element Checkout** (commit `3dd7c24`):
- `CheckoutsController`: `new` (GET /checkout, redirects on empty cart), `create` (POST /checkout JSON — builds Order + LineItems, creates Stripe PaymentIntent, returns `{clientSecret, orderId}`), `confirmation` (GET /checkout/confirmation?payment_intent=pi_... — retrieves PI status, updates order to paid, wipes cart).
- `app/views/checkouts/new.html.erb`: two-column layout (email field + Payment Element mount target on left; order summary sidebar on right). Loads `stripe.js` via `content_for :head`. Stimulus `checkout` controller wires the form.
- `app/views/checkouts/confirmation.html.erb`: shows "Payment confirmed!" for paid orders, "Payment processing…" with meta-refresh fallback for pending.
- `app/javascript/controllers/checkout_controller.js`: Stimulus controller — on Pay click: validates email, POSTs to `/checkout` for `clientSecret`, mounts Stripe Payment Element, calls `stripe.confirmPayment({ redirect: "if_required" })`, redirects to confirmation URL on success.
- Routes: `GET/POST /checkout`, `GET /checkout/confirmation` (named `checkout_confirmation`).
- Checkout CSS added to `application.css`: `.checkout-layout` (two-column grid), `.checkout-section`, `.checkout-error`, `.checkout-summary`, `.checkout-item-*`, `.checkout-total-row`, `.checkout-confirmation`, `.confirmation-icon`, `.confirmation-details`, responsive collapse for mobile.
- `test/test_helpers/stripe_helper.rb` (already written in 3.4 setup): `with_stripe_payment_intent` helper included in `ActionDispatch::IntegrationTest`.
- 13 new integration tests in `test/integration/checkout_test.rb`.
- Full suite: **386 runs, 954 assertions, 0 failures**.

**Phase 3.3 — Shopping Cart** (commit `a704a09`):
- Migrations: `carts` (optional user_id with partial unique index), `cart_items` (cart+product+price+quantity, unique on cart+product).
- `Cart` model: `add_or_update_item` (find-or-increment), `merge_from` (anonymous → user on login), `total_cents` (SQL SUM), `total_display`, `item_count`, `empty?`.
- `CartItem` model: quantity validation, `total_cents`, `total_display`.
- `CartManagement` concern: `set_cart_data` before_action (skips DB if no session), `current_cart` (find-or-create for user or anonymous), `merge_session_cart_for`.
- `ApplicationController` now includes `CartManagement`.
- `CartsController`: `show`, `add_item`, `update_item`, `remove_item`; all respond to both HTML and Turbo Stream.
- `SessionsController#create` captures anonymous cart ID before `start_new_session_for`, then calls `merge_session_cart_for`.
- Routes: `resource :cart, only: :show`; `POST/PATCH/DELETE /cart/items`.
- Views: `carts/show`, `_cart_contents`, `_cart_item`, Turbo Stream templates (`add_item`, `update_item`, `remove_item`).
- Cart drawer in layout: fixed sliding panel, overlay, close button; Stimulus `cart_controller.js` for open/close; Escape key closes drawer.
- Cart icon in header with badge count (`#cart-badge` updated via Turbo Streams).
- "Add to Cart" button on product show page enabled (was disabled placeholder).
- CSS: cart-toggle, cart-panel, cart-overlay, cart-item-list, qty-btn, cart-total.
- 27 new tests (12 model + 15 integration); full suite: **373 runs, 911 assertions, 0 failures**.

**Phase 3.2 — Public Shop UI** (commit `4980bf9`):
- Routes: `GET /shop`, `GET /shop/:slug` (before catch-all).
- `ShopController`: `policy_scope` index (for_sale for non-admins); FriendlyId-aware show; redirects on missing slug.
- `Admin::ProductsController`: FriendlyId `find_resource` override.
- Views: shop/index, shop/show, `_product_card` partial; placeholder cover image when no attachment.
- CSS: `.product-grid`, `.product-card`, `.product-detail` using design-system tokens.
- 12 new integration tests.

**Phase 3.1 — Stripe Integration Foundation** (commit `e1966ad`):
- `stripe` gem (13.5.1) added; `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` are Railway env vars only — not committed.
- `config/initializers/stripe.rb`: sets `Stripe.api_key` from env.
- Models: `Product` (FriendlyId slugged+history, draft/active/archived enum, polymorphic productable, `active_price`, `display_price`, `format_money`), `Price` (amount_cents, currency, active flag), `Order` (optional user for guest checkout, email normalization, pending/paid/failed/refunded enum), `LineItem`, `StripeCustomer` (one-per-user unique index).
- 5 migrations: stripe_customers, products, prices, orders, line_items.
- Pundit policies: `ProductPolicy`, `PricePolicy`, `OrderPolicy` with Scope classes.
- Administrate dashboards: `ProductDashboard` (ActiveStorage cover_image, HasMany prices, collection filters), `PriceDashboard`, `OrderDashboard` (read-only form attributes).
- Admin stub controllers: `Admin::ProductsController`, `Admin::OrdersController`.
- `StripeWebhooksController` at root: CSRF-exempt, `allow_unauthenticated_access`, handles `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`; rescues `JSON::ParserError` and `Stripe::SignatureVerificationError` with 400.
- Routes: `post "webhooks/stripe"`, admin `resources :products`, admin `resources :orders, only: %i[index show]`.
- 48 new tests. **Minitest 6 note:** `stub` method was removed in Minitest 6 — webhook tests replace `Stripe::Webhook.construct_event` via `define_singleton_method`/`method` with restore in ensure.
- Full suite: **334 runs, 822 assertions, 0 failures**.

**Phase 2.4 — User Administration** (commit `ae2a0f4`):
- `banned_at` on User; `User#banned?`, `#ban!`, `#unban!`.
- SessionsController blocks banned sign-ins with the same wrong-credentials error (no enumeration).
- `ImpersonationLog` model stores `impersonator_session_id` (bigint) so the exit action can restore the admin session from DB — no reliance on Rails session or cookie state across the `start_new_session_for` swap.
- `Admin::ImpersonationsController < ::ApplicationController` — root-namespace prefix prevents Ruby resolving `ApplicationController` to `Admin::ApplicationController`, which would have blocked members from exiting through `authorize_admin_access`.
- Impersonation banner in layout; audit log table on admin user show page.
- Bulk role assignment (`PATCH /admin/users/bulk_role`, admin-only).
- Custom admin user index (search, role/status badges, bulk-role form) and show page.
- `UserPolicy`: `ban?`, `unban?`, `impersonate?` (admin only, cannot target another admin), `bulk_role?`.
- 28 new tests (23 integration + 5 model). Full suite: **286 runs, 732 assertions, 0 failures**.

**Phase 2.3 — User Roles Expansion** (commit `673e60e`):
- Added `member` (3) and `subscriber` (4) to User role enum.
- Self-registration now defaults to `member` (not `author`); authors are promoted by admin.
- `User#admin_accessible?` and `#content_creator?` instance helpers.
- `ApplicationPolicy`: shared private helpers `admin_accessible?`, `content_creator?`, `subscriber_or_above?`.
- `PostPolicy`: `create?` restricted to content creators; `show?` and `Scope` gate subscriber-only posts by `requires_subscriber` column.
- `PagePolicy`: `index?/create?/update?` tightened to `admin_accessible?`.
- Migration: `posts.requires_subscriber boolean NOT NULL DEFAULT false`.
- `PostDashboard`: `requires_subscriber` field on show/form pages.
- 38 new tests (23 model + 15 integration). Full suite: **258 runs, 649 assertions, 0 failures**.

**Phase 2.2 — Self-Service Registration** (commit `fc38a88`):
- Migrations: `email_verified_at`, `email_verification_token`, `email_verification_sent_at` on users (partial unique index on token); `site_settings` table (key/value/value_type/description).
- User model: `email_verified?`, `generate_email_verification_token!`, `verify_email!`; `validates :email_address, uniqueness` added.
- `SiteSetting` model: `get`/`set`/`invite_only?` typed class API with DEFAULTS fallback.
- `SendEmailVerificationJob` + `UserMailer#email_verification` (HTML + text, 48h expiry note).
- `RegistrationsController`: `GET/POST /register` (invite-only gate, role lock, redirect-if-authenticated); `GET /register/verify?token=` (lookup, 48h expiry, auto-sign-in on success); `POST /register/resend` (enumeration-safe).
- `SessionsController`: hard blocks unverified users — redirects to verify page.
- `Admin::SiteSettingsController`: admin-only `GET/PATCH /admin/settings` (invite_only toggle).
- Administrate nav override: "Site Settings" link visible to admin role.
- Auth layout: CSP nonce added to inline theme script.
- `ApplicationMailer`: `from` reads `ACTION_MAILER_FROM` env var.
- Seeds: backfills `email_verified_at`; seeds default `SiteSetting`.
- Fixtures + test_helper: parallelization threshold raised 200→500.
- 42 new tests (14 model + 28 integration). Full suite: **220 runs, 592 assertions, 0 failures**.

**Phase 2.1 — User Profile** (commit `23cb868`):
- Migration: `bio` (text) + `website_url` (string) on users; partial unique index `LOWER(display_name)`.
- User model: `has_one_attached :avatar`; validates bio ≤ 280 chars, website_url http/https format, display_name case-insensitive unique ≤ 50 chars; avatar image-only < 10 MB.
- `UserPolicy#show_profile?` = true (public); `SettingPolicy` gates settings to authenticated users.
- `MembersController` — `GET /members/:display_name`; case-insensitive lookup; 404 for missing; shows up to 6 published posts by that author.
- `SettingsController` — `GET /settings` + `PATCH /settings` (profile + email) + `PATCH /settings/update_password` (with current-password verification, 12-char min).
- Site header: "Settings" link for authenticated users, "Sign in" link for guests.
- `UserDashboard` updated with bio + website_url for Administrate.
- 143 lines of new CSS: `.avatar` sizes, `.member-profile`, `.settings-section`, `.settings-form`.
- 38 new tests (15 model + 23 integration). Full suite: **178 runs, 488 assertions, 0 failures**.

**Phase 1.5 — Blog System Enhancements** (commit `f906f4b`):
- `Post#reading_time` (words ÷ 200, min 1 minute) displayed in post byline.
- Related posts: `PostsController#show` loads up to 3 live posts sharing any category; rendered as compact grid below body.
- RSS 2.0 feed at `/feed.xml` (`FeedController`, 20 most-recent published posts, public).
- `Series` model (FriendlyId, has_many :posts ordered by series_position); migration adds `series_id` + `series_position` to posts; public `/series/:slug` route + landing page with numbered post list; SeriesDashboard + SeriesPolicy.
- Draft preview already handled by `PostPolicy#show?` — no extra code needed.
- 23 new tests. Full suite: **140 runs, 398 assertions, 0 failures**.

**Phase 1.4 — Third-Party Embed Widgets** (commit `950a827`):
- `EmbedParser` PORO: YouTube, Vimeo, Spotify, SoundCloud, Apple Music URL-to-embed-URL conversion.
- Shared `_embed.html.erb` partial with 16:9 ratio container or fixed-height iframe by provider.
- `Admin::EmbedsController#preview` — `GET /admin/embeds/preview?url=URL`; Pundit-gated to editor+.
- Stimulus `embed_picker_controller.js`: adds "Embed" button to Trix toolbars, shows URL input panel, calls preview endpoint and shows live iframe preview.
- CSP enabled: `frame-src` enforced for 5 providers; nonce-based `script-src` + `strict-dynamic`; inline theme script updated with `content_security_policy_nonce`.
- 32 new tests. Full suite: **117 runs, 340 assertions, 0 failures**.

**Phase 1.3 — Video Player** (commit `088e824`):
- Stimulus `video_player_controller.js`: same lifecycle pattern as audio player; adds screen-click toggle, fullscreen via `requestFullscreen()` on the container, `_handleFullscreenChange` swapping aria-label and toggling `.is-fullscreen`.
- Shared partial `app/views/shared/_video_player.html.erb`: video screen + controls bar. Accepts `poster_url` and `show_download` locals. Source supports MP4 and WebM.
- Admin media show page renders the video player for video-type media.
- `~215` lines of CSS including fullscreen state (`:fullscreen` + `:-webkit-full-screen`).
- README: AVI → MP4 re-encode FFmpeg instructions.
- 12 integration tests. Full suite: **85 runs, 251 assertions, 0 failures**.

**Phase 1.2 — Audio Player** (commit `44b5b56`):
- Stimulus `audio_player_controller.js`: play/pause toggle, seek scrubber with CSS-gradient progress track, volume slider, playback speed select, tabular time display, aria attributes, clean connect/disconnect lifecycle.
- Shared partial `app/views/shared/_audio_player.html.erb`: accepts any audio `Medium`; `show_download` local controls download link visibility.
- Admin media show page renders the player for audio files.
- ~190 lines of CSS using design-system tokens; responsive (hides volume/speed on narrow screens).
- 10 integration tests. Full suite: **73 runs, 231 assertions, 0 failures**.

**Phase 1.1 — Media Manager** (commit `06a7d2f`):
- `Medium` model: polymorphic owner, image/audio/video/document enum, 200 MB cap, content-type allow-list, `byte_size` cached via `after_create_commit`.
- Pundit policy: editors upload/edit; admins only delete.
- `Admin::MediaController`: grid index with filter tabs, search, Pagy (24/page), CRUD, and `bulk_destroy` collection action.
- Stimulus `upload_controller.js`: drag-and-drop zone, multi-file Fetch API loop.
- `MediumDashboard` stub so Administrate nav registers the resource.
- ~350 lines of media-library CSS (drop zone, grid, cards, type badges, bulk bar, dark-mode tokens).
- 30 new tests (15 model + 15 integration). Full suite: **63 runs, 213 assertions, 0 failures**.

Previous milestones: Rails 8 foundation → auth/Pundit → Page/Post/Category → Administrate admin → public Hotwire site → Railway deployment → admin UX polish → design system → pre-Phase-1 gaps closed → Phase 1.1 Media Manager.

## Active Task

Phase 3.6 complete. Phase 3 E-Commerce is done. Moving to **Phase 3.7 — Email Notifications**: order confirmation email on checkout, download-ready notification, refund receipt. All infrastructure (Action Mailer, Solid Queue, `UserMailer`, `SendEmailVerificationJob` pattern) is in place. SMTP Railway env vars must be set before emails deliver. See ROADMAP.md Phase 3.7.

## Architecture (rules — never break without explicit owner approval)

- `Page` and `Post` are **separate models, separate tables**. No STI. No `type` column.
- **Pundit** for all authorisation. No shortcuts that skip policy checks.
- **Rails 8 generated auth**. Do not add Devise.
- **Minitest** for all tests. Do not migrate to RSpec.
- **Propshaft** for assets. No Webpack or Sprockets.
- **No Redis.** Solid Queue / Cache / Cable use PostgreSQL.
- **No React.** Public site is Hotwire/Turbo. Admin is Administrate.
- **Stripe only** for payments (Phase 3+).
- **Anthropic / Claude** for AI integration (Phase 7+).
- Database is a **Rails island** — no other app shares this PostgreSQL instance.
- **No secrets in the repo.** `RAILS_MASTER_KEY` and all API keys are Railway env vars only.

## Current Content Model

### Publishing
- `Page` — standalone/hierarchical. Action Text `body`, Active Storage `hero_image`, `Publishable`, `Seoable`, FriendlyId slug, `show_in_nav`, `position`, optional `parent`/`children` self-join
- `Post` — dated editorial. Action Text `body`, Active Storage `cover_image` + `gallery`, `author` (User), `categories` (through `taggings`), `Publishable`, `Seoable`, FriendlyId slug + history, `reading_time`, `requires_subscriber`, `series_id`/`series_position`
- `Category` — FriendlyId taxonomy for posts. Many-to-many with Post via `taggings` join table
- `Series` — ordered collection of posts. FriendlyId slug; posts carry `series_position`
- `Medium` — media library asset. Enum: `image`/`audio`/`video`/`document`; 200 MB hard cap; `byte_size` cached via `after_create_commit`; polymorphic `owner`

### Users & Auth
- `User` — roles: `author` (0), `editor` (1), `admin` (2), `member` (3), `subscriber` (4). Key columns: `email_address`, `display_name` (case-insensitive unique), `role`, `bio`, `website_url`, Active Storage `avatar`, `banned_at`, `email_verified_at`, `email_verification_token`. Helpers: `admin_accessible?`, `content_creator?`, `banned?`
- `Session` — Rails 8 generated token-based session model
- `ImpersonationLog` — records Login-as sessions; `impersonator_session_id` bigint enables DB-based admin session restore on exit
- `SiteSetting` — typed key/value store; `SiteSetting.invite_only?`, `.get(key)`, `.set(key, value)`

### E-Commerce (Phase 3)
- `Product` — FriendlyId, status enum (`draft`/`active`/`archived`), polymorphic `productable`, Active Storage `cover_image`, `has_many_attached :download_files`, helpers: `active_price`, `display_price`, `format_money(cents, currency)`
- `Price` — `amount_cents`, `currency` (ISO), boolean `active`; belongs_to `product`
- `Order` — optional `user` (guest checkout allowed), `email` (normalized), status enum (`pending`/`paid`/`failed`/`refunded`), `total_cents`, `currency`, `stripe_payment_intent_id`; `total_display` money helper
- `LineItem` — belongs_to `order`, `product`, `price`; `quantity`, `unit_amount_cents`
- `Cart` — optional `user_id` with partial unique index (allows unlimited anonymous rows), `session_token`. Methods: `add_or_update_item`, `merge_from(other)`, `total_cents`, `item_count`, `empty?`
- `CartItem` — belongs_to `cart`, `product`, `price`; `quantity`; `total_cents`, `total_display`
- `StripeCustomer` — one-per-user; `stripe_customer_id`; unique index on `user_id`

### Concerns
- `Publishable` — status enum (`draft`/`published`/`archived`), `live` scope, auto-sets `published_at` on first publish
- `Seoable` — `meta_title`, `meta_description`, `og_image` columns; `meta_description` wired to `<meta name="description">` via layout `content_for(:description)`. No model-level validators yet.

## Design System (current state)

- **Font:** Inter variable font (Google Fonts `@import` in CSS)
- **Light:** `--bg #f8f7f5`, `--bg-elevated #ffffff`, `--text #18150e`, `--accent #e8440a`
- **Dark:** `--bg #0f0e0d`, `--bg-elevated #1a1816`, `--text #f0ece4`, `--accent #e8440a`
- **Theme switch:** `data-color-scheme` attribute on `<html>` + `@media (prefers-color-scheme: dark)` + no-flash localStorage script
- **Auth layout:** `app/views/layouts/auth.html.erb` — centred card, brand at top, no nav
- **All new UI** must use the existing CSS custom properties. No hard-coded colours or fonts.

## Windows Command Prefix

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms
ruby bin\rails test
```

## Test Suite

```
418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips
```

Key test files:

**Phase 1 — Media**
- `test/integration/public_cms_routes_test.rb` — page/post/category/series public routes
- `test/integration/admin_access_test.rb` — role-based admin gate
- `test/integration/admin_content_management_test.rb` — Page/Post/Category/Series CRUD
- `test/integration/seeds_test.rb` — idempotent seed smoke test
- `test/models/active_storage_variant_test.rb` — Active Storage variant background enqueue

**Phase 2 — Users**
- `test/integration/registration_test.rb` — email verification flow, invite-only gate, 48h expiry, resend
- `test/models/site_setting_test.rb` — typed get/set/invite_only? API
- `test/integration/member_access_test.rb` — member vs subscriber content gates, `requires_subscriber` guard
- `test/integration/user_administration_test.rb` — ban/unban (no enumeration), Login-as impersonation, bulk role, custom views
- `test/models/impersonation_log_test.rb` — DB-based session restore for impersonation exit

**Phase 3 — E-Commerce**
- `test/integration/stripe_webhooks_test.rb` — `payment_intent.succeeded`, `payment_failed`, `charge.refunded`; HMAC verification; `define_singleton_method` mocking
- `test/models/product_test.rb` — status enum, FriendlyId, `active_price`, `format_money`, `download_files` attachment
- `test/models/price_test.rb` — validations, currency
- `test/models/order_test.rb` — status transitions, email normalization, `total_display`
- `test/models/line_item_test.rb` — totals, validations
- `test/models/stripe_customer_test.rb` — one-per-user unique index
- `test/models/cart_test.rb` — `add_or_update_item`, merge-on-login, `total_cents`, `item_count`
- `test/models/cart_item_test.rb` — quantity validation, `total_cents`
- `test/integration/shop_test.rb` — public shop index/show, draft hidden from non-admins
- `test/integration/cart_test.rb` — add/update/remove items, anonymous cart, merge on login, Turbo Stream responses
- `test/integration/checkout_test.rb` — `create` returns `clientSecret`/`orderId`, confirmation, cart wipe, Stripe mock via `with_stripe_payment_intent`
- `test/integration/downloads_test.rb` — index lists purchased products, signed-URL show, authorization (paid-order gate), `define_singleton_method` mocking
- `test/integration/admin_refunds_test.rb` — refund success, auth levels (admin/editor/member/anon), Stripe error leaves order paid, `with_stripe_refund` helper
- `test/integration/admin_revenue_test.rb` — monthly stats, auth levels, empty state, pending orders excluded, formatted money

**Shared helpers**
- `test/test_helpers/stripe_helper.rb` — `with_stripe_payment_intent`, `with_stripe_refund`; both use `define_singleton_method` + `.method()` save/restore in `ensure` (Minitest 6 has no `#stub`)

## Seeds

`ruby bin\rails db:seed` (idempotent):
- Admin: `admin@vybedeck.test` / `password`
- Categories: Announcements, Field Notes
- Pages: home, about
- Posts: launch-notes (pub), editorial-workflow (pub), private-draft (draft)

## Deployment

- Railway auto-deploys from `main` via Dockerfile
- `railway.toml`: `PORT=80` (critical — do not remove), `healthcheckTimeout=600`
- `bin/docker-entrypoint`: retries `db:migrate` 12× before starting Puma
- All 4 DB configs share `DATABASE_URL` in production
- `RAILS_MASTER_KEY` is a Railway env var — never committed

## Known Gaps (priority order)

All pre-Phase-1 gaps closed. Phase 3 E-Commerce complete. Remaining items:

1. **No order confirmation / download / refund emails (Phase 3.7)** — `Action Mailer`, `Solid Queue`, and `UserMailer` scaffolding already exists (email verification pattern). Phase 3.7 adds `OrderMailer` with `confirmation`, `download_ready`, and `refund_receipt` mailer actions.
2. **S3 not yet active** — code is ready (`aws-sdk-s3` gem, `storage.yml` amazon service, `production.rb` switches when `AWS_BUCKET` env var is present). Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` as Railway env vars. **Required before digital downloads are durable in production** — local disk storage is wiped on every Railway deploy.
3. **SMTP not yet active** — config ready in `production.rb`. Add `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` (and optionally `SMTP_PORT`, `ACTION_MAILER_FROM`) as Railway env vars. Needed for: password-reset email (already built), email verification (already built), and all Phase 3.7 transactional emails.
4. **No `libvips`/ImageMagick in Dockerfile** — Active Storage variant transform jobs enqueue correctly but silently fail (no processor in the container image). Add `RUN apt-get install -y libvips` to `Dockerfile` before enabling image variants in production.
5. **`Seoable` concern has no model-level validations** — `meta_title` and `meta_description` are DB columns wired to `<meta>` via layout, but the concern itself has no length/presence validators. Low priority — add in Phase 10 SEO pass.

## Session Protocol

**Start:** Read this file → read `HANDOFF.md` → run `ruby bin\rails test` → confirm green.  
**During:** After each significant change: run affected tests. Bug fix = write failing test first.  
**End:** Update this file (Last Completed / Active Task) + `HANDOFF.md` + commit docs.  
**Commits:** `type(scope): message` format. Stage specific files. Never `git add -A` blindly. Never commit `storage/`, `tmp/`, `log/`, or any credential file.
