# VybeDeck CMS — Session Handoff

> New agents read this file first (after `CLAUDE.md`), then `ROADMAP.md`.
> Keep "Last Completed" and "Immediate Next Session" current at the end of every session.

**Updated:** 2026-06-09
**Branch:** `main` — Phase 4.1 pushed to GitHub; Railway auto-deploy triggered
**Last commit:** `40b5ea0` (Phase 4.1 — Community & Forum models, admin, and public UI)
**Test suite:** `490 runs, 1292 assertions, 0 failures, 0 errors, 0 skips`

---

## Where Things Are

| Item | Value |
|------|-------|
| Workspace | `C:\DEV\VybeDeck` |
| Rails app | `C:\DEV\VybeDeck\vybedeck_cms` |
| GitHub | `https://github.com/Vybecode-LTD/VybeDeckCMS.git` |
| Deployed | Railway (auto-deploy from `main`) |
| Branch | `main` — Phase 4.1 pushed; Railway deploy in progress |
| Tests | `490 runs, 1292 assertions, 0 failures, 0 errors, 0 skips` |

---

## Windows Command Prefix

**Always** prepend this before any Rails command in PowerShell:

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms
```

Then:

```powershell
ruby bin\rails test          # run all tests
ruby bin\rails db:seed       # idempotent seed
ruby bin\rails server        # dev server on :3000
```

---

## What Is Built (Phase-by-Phase)

### Foundation (pre-Phase-1)

- **Rails 8.1 monolith** — PostgreSQL primary; Solid Queue/Cache/Cable all share the same `DATABASE_URL` connection in production (Railway single-Postgres constraint)
- **Propshaft** asset pipeline; Importmap for JS; no Webpack; no Node build step; no Redis
- **Rails 8 generated authentication** — `SessionsController`, `PasswordsController`, token-based sessions
- **Pundit** for all authorisation — every controller action has a policy check
- **Content model** — separate `Page` and `Post` (no STI); `Category`; `Publishable` + `Seoable` concerns; FriendlyId slugs throughout
- **Administrate 1.0** admin panel — `PageDashboard`, `PostDashboard`, `CategoryDashboard`, `UserDashboard`; Pundit-gated
- **Public Hotwire site** — `/`, `/blog`, `/topics/:slug`, `/series/:slug`, shared header/footer
- **Design system** — Inter variable font; light/dark OKLCH token themes; `[data-color-scheme]` + `@media prefers-color-scheme`; no-flash localStorage theme script; glass header
- **Railway deployment** — Dockerfile; `railway.toml` (PORT=80 is critical); `bin/docker-entrypoint` with 12-retry `db:migrate` loop; all four DB configs share `DATABASE_URL`

---

### Phase 1 — Content & Media Foundation (commits `06a7d2f` → `f906f4b`)

**1.1 Media Manager** (`06a7d2f`)
- `Medium` model: polymorphic `owner`, enum `media_type` (image/audio/video/document), 200 MB cap, content-type allow-list, `byte_size` cached via `after_create_commit`
- `Admin::MediaController`: grid index with filter tabs, search, Pagy 24/page, CRUD, `bulk_destroy`
- Stimulus `upload_controller.js`: drag-and-drop zone, multi-file Fetch API loop with progress
- Pundit policy: editors upload/edit; admin-only delete

**1.2 Audio Player** (`44b5b56`)
- Stimulus `audio_player_controller.js`: play/pause, seek scrubber with CSS gradient progress track, volume slider, playback speed select (0.5×–2×), tabular time display, full aria attribute support
- Shared partial `app/views/shared/_audio_player.html.erb`; wired into admin media show for audio files

**1.3 Video Player** (`088e824`)
- Stimulus `video_player_controller.js`: same lifecycle as audio; screen-click play/pause toggle; fullscreen via `requestFullscreen()` on the container with `:-webkit-full-screen` CSS fallback
- Shared partial `app/views/shared/_video_player.html.erb` with `poster_url` and `show_download` locals

**1.4 Third-Party Embed Widgets** (`950a827`)
- `EmbedParser` PORO: YouTube (watch/youtu.be/playlist), Vimeo, Spotify (track/album/playlist/artist), SoundCloud, Apple Music
- `Admin::EmbedsController#preview` — `GET /admin/embeds/preview?url=URL`; editor/admin only; Stimulus `embed_picker_controller.js` adds "Embed" button to Trix toolbar
- **CSP enabled**: `frame-src` enforced for 5 providers; nonce-based `script-src` with `strict-dynamic`

**1.5 Blog System Enhancements** (`f906f4b`)
- `Post#reading_time` (words ÷ 200, min 1 minute) shown in byline
- Related posts: up to 3 live posts sharing any category, rendered below body
- RSS 2.0 feed at `/feed.xml` — 20 most recent published posts, public, no auth
- `Series` model (FriendlyId, has_many :posts ordered by `series_position`); `/series/:slug` public route + landing page; `SeriesDashboard`

---

### Phase 2 — User Accounts & Profiles (commits `23cb868` → `ae2a0f4`)

**2.1 User Profile** (`23cb868`)
- `bio` (text, 280 chars), `website_url` (http/https validated), Active Storage `avatar` added to User
- `display_name`: case-insensitive unique partial index (`LOWER(display_name)`), ≤ 50 chars
- Public profile at `/members/:display_name` (`MembersController`) — shows up to 6 published posts by that author
- Settings at `/settings` + `/settings/update_password` — Pundit-gated to authenticated user

**2.2 Self-Service Registration** (`fc38a88`)
- `RegistrationsController`: `GET/POST /register` (invite-only gate, role locked to `member`), `GET /register/verify?token=` (48h expiry, auto-sign-in), `POST /register/resend` (enumeration-safe)
- `SiteSetting` model with typed `get`/`set`/`invite_only?` API; `site_settings` table
- `SendEmailVerificationJob` + `UserMailer#email_verification` (HTML + text)
- `SessionsController#create` hard-blocks unverified users — redirects to verify page
- `Admin::SiteSettingsController`: admin-only invite_only toggle at `/admin/settings`
- CSP nonce added to auth layout inline script

**2.3 User Roles Expansion** (`673e60e`)
- Added `member` (3) and `subscriber` (4) to User role enum. Self-registration now defaults to `member`
- `User#admin_accessible?`, `#content_creator?` instance helpers
- `ApplicationPolicy` private helpers: `admin_accessible?`, `content_creator?`, `subscriber_or_above?`
- `PostPolicy`: `create?` restricted to content creators; `show?` + `Scope` gate subscriber-only posts via `requires_subscriber` column
- Migration: `posts.requires_subscriber boolean NOT NULL DEFAULT false`

**2.4 User Administration** (`ae2a0f4`)
- `banned_at` on User; `ban!`/`unban!`; `SessionsController` blocks banned sign-ins with identical wrong-credentials error (no enumeration)
- `ImpersonationLog` model: stores `impersonator_session_id` (bigint) in DB — admin session is retrievable on impersonation exit regardless of cookie state
- `Admin::ImpersonationsController < ::ApplicationController` — root-namespace prefix prevents `authorize_admin_access` from blocking member-role users when they exit impersonation
- Impersonation banner in site layout; audit log table on admin user show page
- Bulk role assignment: `PATCH /admin/users/bulk_role`, Pundit admin-only
- Custom admin user index (search, role badges, status badges, bulk-role form) and show page

---

### Phase 4 — Community & Forum (commit `40b5ea0`)

**4.1 Forum Core** (`40b5ea0`)
- `Forum` (FriendlyId, visibility enum open/members_only/subscribers_only, position, icon); `ForumThread` (title, Action Text body, author, forum, pinned, locked, view_count, reply_count counter_cache, last_reply_at); `ForumReply` (Action Text body, author, forum_thread, likes_count, is_solution); 3 migrations
- `ForumPolicy` — scope filters visible forums per role; `show?` gates by visibility; `ForumThreadPolicy` — `lock?`/`pin?` editor/admin only; `ForumReplyPolicy` — `create?` blocked on locked threads; all three policies add `index?`/`show?` for Administrate
- Admin: `ForumDashboard`, `ForumThreadDashboard`, `ForumReplyDashboard`; `Admin::ForumThreadsController` — PATCH `:lock` and `:pin` member actions toggle locked/pinned with flash notice
- `CommunityController`: `allow_unauthenticated_access` + `before_action :resume_session` (required so `Current.user` is populated for signed-in visitors on public pages, same pattern as `PostsController`); write actions gated via `require_authentication`; Turbo Stream reply response (`create_reply.turbo_stream.erb`)
- **Known bug fixed:** `authorize @forum` in `forum` action derived action name → called nonexistent `forum?` on ForumPolicy; corrected to `authorize @forum, :show?`
- **Known bug fixed:** `ForumReply#reset_thread_last_reply_at` crashed during cascade delete because parent thread was already destroyed; guarded with `return if forum_thread.destroyed?`
- Routes: `/community/*` ordered before `/*id` page catch-all; admin namespace extended
- 46 new integration tests covering visibility gates, auth gates, Turbo Stream reply, locked-thread guard, view-count increment, admin CRUD, lock/pin toggle

**Remaining Phase 4 sub-phases (not started):**
- 4.2 — Reactions & Moderation Queue (reply likes; report flag → admin queue; approve/remove)
- 4.3 — Per-reply admin delete (placeholder comment already in `_reply.html.erb`)
- 4.4 — Notification bell (`Notification` model; thread-reply notifications; Turbo Stream unread badge)
- 4.5 — Per-forum accent colour (`colour_hex` column; applied to forum card/thread headers)

---

### Phase 3 — E-Commerce & Payments (commits `e1966ad` → `56ab9a6`)

**3.1 Stripe Integration Foundation** (`e1966ad`)
- `stripe` gem (13.5.1); `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` stored as Railway env vars — never committed
- `config/initializers/stripe.rb` sets `Stripe.api_key` from env
- Models: `Product` (FriendlyId slugged+history, `draft`/`active`/`archived` enum, polymorphic `productable`, `active_price`, `display_price`, `format_money`), `Price` (amount_cents, currency, active flag), `Order` (optional user for guest checkout, email normalization, `pending`/`paid`/`failed`/`refunded` enum, `total_display`), `LineItem`, `StripeCustomer` (one-per-user unique index)
- 5 migrations: `stripe_customers`, `products`, `prices`, `orders`, `line_items`
- Pundit policies: `ProductPolicy`, `PricePolicy`, `OrderPolicy` with Scope classes
- Administrate dashboards: `ProductDashboard`, `PriceDashboard`, `OrderDashboard` (read-only form)
- `StripeWebhooksController` at root: CSRF-exempt, `allow_unauthenticated_access`; handles `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`; rescues `JSON::ParserError` and `Stripe::SignatureVerificationError` with 400
- **Minitest 6 note:** `Object#stub` was removed in Minitest 6. All Stripe class method replacement uses `define_singleton_method` + `.method()` save/restore in `ensure`. This pattern is used consistently in `StripeHelper` and inline webhook tests.

**3.2 Public Shop UI** (`4980bf9`)
- `ShopController`: `policy_scope` on index (hides non-active for non-admins); FriendlyId-aware `show` with graceful slug-redirect; `Admin::ProductsController` with `find_resource` override
- Routes: `GET /shop`, `GET /shop/:slug` — must come before the `/*id` page catch-all
- Views: `shop/index`, `shop/show`, `_product_card` partial; placeholder cover image fallback
- CSS: `.product-grid`, `.product-card`, `.product-detail` using design-system tokens

**3.3 Shopping Cart** (`a704a09`)
- Migrations: `carts` (optional `user_id` with partial unique index `WHERE user_id IS NOT NULL`), `cart_items` (cart+product+price+quantity, unique on cart+product)
- `CartManagement` concern: `set_cart_data` before_action (skips DB if no session), `current_cart`, `merge_session_cart_for`; included in `ApplicationController`
- `SessionsController#create` captures anonymous `cart_id` from session **before** `start_new_session_for` (session is wiped on login — must save ID first)
- `CartsController`: `show`, `add_item`, `update_item`, `remove_item`; respond to HTML and Turbo Stream
- Cart drawer in layout: fixed sliding panel, overlay, Stimulus `cart_controller.js` (open/close + Escape key)
- `#cart-badge` and `#cart-panel-body` DOM IDs updated via Turbo Streams on mutations

**3.4 Stripe Payment Element Checkout** (`3dd7c24`)
- `CheckoutsController#create` (POST JSON): builds `Order` + `LineItems`, calls `Stripe::PaymentIntent.create`, returns `{clientSecret, orderId}`
- `CheckoutsController#confirmation`: retrieves PaymentIntent status, marks order `:paid`, wipes cart
- Stimulus `checkout_controller.js`: validates email, POSTs for `clientSecret`, mounts Stripe Payment Element, calls `stripe.confirmPayment({ redirect: "if_required" })`
- Two-column checkout layout (Payment Element + order summary sidebar); responsive mobile collapse
- Routes: `GET/POST /checkout`, `GET /checkout/confirmation`

**3.5 Digital Downloads** (`c727281`)
- `Product` gets `has_many_attached :download_files` — zero migrations needed (Active Storage)
- `User` gets `has_many :orders, dependent: :nullify` — enables `user.orders.paid.joins(:line_items)` purchase check
- `ProductPolicy#download?`: admins/editors always allowed; regular users need a paid `Order` containing the product via `LineItem`
- `DownloadsController`: `index` lists products from paid orders that have files attached; `show` looks up blob by `ActiveStorage::Blob.find_signed!(params[:id])`, verifies ownership via `ActiveStorage::Attachment`, authorises via `ProductPolicy#download?`, redirects to `rails_blob_path(blob, disposition: "attachment")`
- `ActiveStorageMultiField` Administrate custom field: overrides `self.permitted_attribute` to return `{ attr => [] }` (required for `has_many_attached` strong-params in Administrate)
- Templates at `app/views/fields/active_storage_multi_field/` — `_form`, `_show`, `_index`
- `ProductDashboard` updated with `download_files: ActiveStorageMultiField`

**3.6 Refunds & Admin Order Management** (`56ab9a6`)
- `Admin::OrdersController#refund` (POST): guards `paid?` status, calls `Stripe::Refund.create(payment_intent:)`, marks order `:refunded`; rescues `Stripe::StripeError` with flash alert leaving order unchanged
- Custom `app/views/admin/orders/show.html.erb`: status pill badge (CSS class by status), "Issue Full Refund" button visible to admin+paid only (with `turbo_confirm` dialog), `total_display` formatted money, `← All Orders` breadcrumb
- `Admin::RevenueController#show`: monthly stats via `DATE_TRUNC('month', created_at)` grouped by month+currency (last 12 months); all-time totals by currency; Pundit via `RevenuePolicy#show?` (editor/admin)
- `app/views/admin/revenue/show.html.erb`: all-time summary cards + monthly breakdown table
- Revenue link in admin navigation (editor/admin only)
- `resource :revenue, only: :show, controller: :revenue` — explicit `controller:` option required because Rails auto-pluralises `revenue` → `revenues` → `Admin::RevenuesController` even for singular resources
- `LineItemDashboard` created — required because `OrderDashboard` declares `line_items: Field::HasMany` (Administrate looks up `LineItemDashboard` when rendering the order show page)
- `StripeHelper#with_stripe_refund` added to `test/test_helpers/stripe_helper.rb`

**3.7 Email Notifications + Security Remediation** (`f0ba7d7`, `9f28005`)
- `Admin::ApplicationController` — `include Pundit::Authorization` replaced with `include Administrate::Punditize`; all Administrate base CRUD methods now auto-enforce `policy_scope!` / `authorize`
- `CategoryPolicy` — new; `index?`/`show?`/`create?`/`update?` = `admin_accessible?`; `destroy?` = admin-only; `Scope` returns `scope.all`
- `Admin::UsersController` — explicit `authorize User, :index?` in `index`; explicit `authorize @user, :show?` in `show` (these override Administrate base methods, so Punditize cannot reach them automatically)
- `Admin::MediaController` — explicit `authorize` on all 8 actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`, `bulk_destroy` (fully custom controller, no Administrate base methods)
- `Admin::PagesController` + `Admin::PostsController` — `find_resource(param)` override using `resource_class.friendly.find(param)` fixes FriendlyId slug resolution for admin delete/edit/show routes
- `OrderMailer#confirmation(order)` — itemised order receipt; `@line_items` loaded with `includes(:product, :price)` for N+1 safety
- `OrderMailer#download_ready(order)` — filters only line items where `product.download_files.attached?`; links to `account_downloads_url` for signed-in users, sign-in prompt for guests
- `OrderMailer#refund_receipt(order)` — refund amount and order reference
- HTML + text templates for all three mailer actions
- `SendOrderConfirmationJob` — `Order.where(id:, confirmation_email_sent_at: nil).update_all(...)` atomic claim; sends `download_ready` when any product has download files
- `SendRefundReceiptJob` — same idempotency pattern with `refund_receipt_sent_at`
- Migration `20260609165539_add_email_timestamps_to_orders` — two nullable datetime columns on `orders`
- Wired: `CheckoutsController#confirmation` after `@order.update!(status: :paid)`; `StripeWebhooksController#handle_payment_intent_succeeded`; `Admin::OrdersController#refund` after Stripe refund success (before rescue)
- 26 new tests across `test/mailers/` (3 files, 6 tests) and `test/jobs/` (3 files, 13 tests), plus regression tests in `test/integration/`

---

## Seeds

`ruby bin\rails db:seed` is idempotent:

| Field | Value |
|-------|-------|
| Admin email | `admin@vybedeck.test` |
| Admin password | `password` |
| Admin role | `admin` |

Also seeds: `Announcements` and `Field Notes` categories; `home` and `about` pages; `launch-notes` (published) + `editorial-workflow` (published) + `private-draft` (draft) posts.

---

## Architecture Rules (never break)

- **`Page` ≠ `Post`.** Separate models, separate tables. No STI. No `type` column. Ever.
- **Pundit only.** No `before_action :authorize` shortcuts that bypass policy classes.
- **No secrets in the repo.** `RAILS_MASTER_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `AWS_*`, `SMTP_*`, `ANTHROPIC_API_KEY` — all Railway env vars.
- **Minitest, not RSpec.** Do not migrate. All Stripe mocking uses `define_singleton_method` (no `#stub` in Minitest 6).
- **Propshaft, not Sprockets.** CSS `@import` is browser-resolved, not bundled.
- **No Redis.** Solid Queue/Cache/Cable for all async.
- **No React.** Public site is Hotwire/Turbo. Admin is Administrate.
- **One release creator.** Railway auto-deploys from `main`. Never `git push --force` to main.
- **Database is a Rails island.** No other app shares this PostgreSQL instance.
- Commits: `type(scope): message` conventional format. Never `git add -A` blindly. Never commit `storage/`, `tmp/`, `log/`, or any credential file.

---

## Known Issues & Gaps

| # | Issue | Severity | Notes |
|---|-------|----------|-------|
| 1 | `Seoable` has no model validators | Low | Columns exist and are wired to `<meta>` tags. Phase 10 adds validators/canonical/OG/JSON-LD. |

### Resolved (2026-06-09)
| Item | Resolution |
|------|------------|
| SMTP | ✅ Resend SMTP active — `smtp.resend.com:587`, domain `send.vybedeck.com` verified, `ACTION_MAILER_FROM=no-reply@send.vybedeck.com` |
| S3/Storage | ✅ Cloudflare R2 active — bucket `vybedeck-production`, endpoint `https://4558289...r2.cloudflarestorage.com`, `storage.yml` updated with `AWS_ENDPOINT` support |
| libvips | ✅ Was never missing — `libvips` is already in Dockerfile line 19 |

---

## Immediate Next Session Checklist

```powershell
# 1. Set PATH
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms

# 2. Confirm green baseline
ruby bin\rails test
# Expected: 490 runs, 1292 assertions, 0 failures

# 3. Implement Phase 4.2 or 4.4 (see options below)
#    OR implement Phase 4.4 — Notification Bell (higher user value)
```

**Next phase options (priority order):**

1. **Phase 4.2 — Reactions & Moderation Queue**
   - Add `likes_count` increment via `ForumReply#like!` and a `POST /community/:slug/:id/replies/:reply_id/like` route
   - Add `reported_at` / `report_reason` to ForumReply; `POST /community/:slug/:id/replies/:reply_id/report`
   - Admin moderation queue: `GET /admin/moderation` listing reported replies; approve/remove actions

3. **Phase 4.4 — Notification Bell** (higher UX value, can skip 4.2/4.3)
   - `Notification` model: `recipient` (User), `actor` (User), `notifiable` (polymorphic), `read_at`
   - `after_create_commit` on ForumReply: creates Notification for thread author (if different from reply author)
   - Notification bell in site header: counter badge; `GET /notifications` list page; mark-as-read Turbo Stream action

---

## File Map (unusual or easy-to-forget)

```
app/fields/active_storage_field.rb           Custom Administrate field for has_one_attached
app/fields/active_storage_multi_field.rb     Custom Administrate field for has_many_attached
app/views/fields/active_storage/             _form and _show partials for single attachment
app/views/fields/active_storage_multi_field/ _form, _show, _index partials for multi-attachment
app/views/admin/application/_form.html.erb   Overrides default Administrate form to add multipart:true
app/views/admin/application/_navigation.html.erb  Custom nav — adds Media, Revenue links
app/views/admin/orders/show.html.erb         Custom order show: status pill, refund button, total_display
app/views/admin/pages/show.html.erb          `cms_page` alias avoids clash with Administrate presenter class
app/views/layouts/auth.html.erb              Separate auth layout: centred card, no nav
app/assets/stylesheets/application.css       ALL design tokens, themes, component CSS (single file — Propshaft)
app/dashboards/line_item_dashboard.rb        Required by OrderDashboard HasMany field — read-only, no routes
app/policies/download_policy.rb             DownloadPolicy — index? for any authenticated user
app/policies/revenue_policy.rb              RevenuePolicy — show? for editor/admin
config/initializers/stripe.rb               Sets Stripe.api_key from env
bin/docker-entrypoint                        12-retry db:migrate loop before Puma starts
railway.toml                                 PORT=80 is CRITICAL — Thruster needs it; do not remove
config/database.yml (production)             All 4 DB configs share DATABASE_URL
test/test_helpers/stripe_helper.rb           with_stripe_payment_intent / with_stripe_refund helpers
```

---

## Recent Commit History

| Hash | Message |
|------|---------|
| `40b5ea0` | feat(community): Phase 4.1 — Forum models, admin, and public UI |
| `9f28005` | feat(email): Phase 3.7 - order email notifications + Tier 2/3 test debt |
| `f0ba7d7` | feat(security): Tier 1 - Administrate::Punditize, CategoryPolicy, FriendlyId admin fixes |
| `699b1d1` | docs: comprehensive documentation audit and update |
| `56ab9a6` | feat(admin): Phase 3.6 - Refunds & Admin Order Management |
| `c727281` | feat(downloads): Phase 3.5 — Digital Downloads |
| `3dd7c24` | feat(checkout): Phase 3.4 — Stripe Payment Element checkout |
| `a704a09` | feat(cart): Phase 3.3 — session-based shopping cart with drawer UI |
| `4980bf9` | feat(shop): Phase 3.2 — public shop UI and admin product CRUD |
| `96206c9` | docs: update CLAUDE.md with Phase 3.1 commit hash |
| `e1966ad` | feat(commerce): Phase 3.1 — Stripe integration foundation |
| `ae2a0f4` | feat(admin): Phase 2.4 - User Administration |
| `673e60e` | feat(auth): Phase 2.3 - User Roles Expansion |
| `fc38a88` | feat(auth): Phase 2.2 - Self-Service Registration |
| `23cb868` | feat(users): Phase 2.1 - User Profile |
| `f906f4b` | feat(blog): Phase 1.5 - Blog System Enhancements |
| `950a827` | feat(media): Phase 1.4 — Third-Party Embed Widgets |
| `088e824` | feat(media): Phase 1.3 — Video Player |
| `44b5b56` | feat(media): Phase 1.2 — Audio Player |
| `06a7d2f` | feat(media): Phase 1.1 — Medium model, admin media library, drag-drop upload |
