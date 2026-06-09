# VybeDeck CMS — Product Roadmap

> **Owner:** Vybecode Ltd  
> **Updated:** 2026-06-09  
> **Branch:** `main`  
> **Maintained by:** session-orchestrator / memory-updater

---

## Vision

VybeDeck CMS will be a full-featured, self-hosted creative-industry publishing platform
built on Rails 8. It targets music labels, independent artists, and creative agencies
who need a single back-office that handles publishing, media management, community,
e-commerce, and collaborative album production — all inside one deployable monolith.

---

## ✅ Completed

| Area | Detail |
|------|--------|
| Rails 8 foundation | PostgreSQL, Solid Queue/Cache/Cable, Propshaft, Importmap |
| Auth | Rails 8 generated auth, rate-limited, session management |
| Authorisation | Pundit, roles: `author`, `editor`, `admin` |
| Content models | Separate `Page` and `Post`; `Category`; `Publishable`; `Seoable` |
| Admin panel | Administrate 1.0, Page/Post/Category/User dashboards, Pundit-gated |
| Admin UX polish | ActiveStorage field, collection filters, view-on-site links, image hints |
| Public Hotwire site | Hero, post grid, topic chips, page templates, shared header/footer |
| Design system | Inter font, light/dark OKLCH tokens, glass header, auth card layout |
| Theme toggle | System-preference + manual toggle; localStorage persistence; no-flash script |
| Railway deployment | Dockerfile, `railway.toml`, PORT=80, healthcheck, retry entrypoint |
| Seeds | Idempotent admin user, categories, pages, posts, generated PNG media |
| User display name | `display_name` column on users; `User#byline` falls back to email |
| Pagination | Pagy (12/page) on blog index and category pages; nav shown when pages > 1 |
| Empty states | Blog index and category show pages show a message when no posts exist |
| Meta description | `Seoable` `meta_description` wired to `<meta name="description">` via layout |
| SMTP config | Production mailer reads `SMTP_*` env vars; silent until set on Railway |
| S3 config | Active Storage switches to `:amazon` when `AWS_BUCKET` env var is present |
| Media Manager | `Medium` model, admin library grid, drag-drop upload, Pundit policy, 30 new tests |
| Audio Player | Stimulus controller, shared partial, play/pause/seek/volume/speed, 10 new tests |
| Video Player | Stimulus controller, shared partial, screen-click, fullscreen, 12 new tests |
| Embed Widgets | EmbedParser PORO (5 providers), admin preview endpoint, Stimulus picker, CSP |
| Blog Enhancements | Reading time, related posts, RSS feed (/feed.xml), Post Series model + landing page |
| User Profile | bio + website_url + avatar on User; `/members/:display_name`; `/settings` with password change |
| Self-Service Registration | Email verification (48h token, hard block on unverified sign-in); `SiteSetting` model; invite-only mode; `RegistrationsController` + `SendEmailVerificationJob` + `UserMailer`; admin settings toggle |
| User Roles Expansion | `member` (3) and `subscriber` (4) roles; self-registration defaults to member; `requires_subscriber` on posts; Pundit policies updated for all 5 roles |
| User Administration | Ban/unban (no enumeration); Login-as impersonation with DB-based session restore + audit log; bulk role assignment; custom admin user list/show views |
| Stripe Integration | `stripe` gem; `Product`, `Price`, `Order`, `LineItem`, `StripeCustomer` models; `StripeWebhooksController`; Pundit policies; Administrate dashboards; webhook tests via `define_singleton_method` (Minitest 6 has no `stub`) |
| Public Shop | `ShopController`; `/shop` index + `/shop/:slug` product detail; product card partial; FriendlyId admin override; design-system CSS |
| Shopping Cart | `Cart`/`CartItem` models; `CartManagement` concern; session-keyed anonymous + user carts; merge on login; Turbo Stream drawer in layout; `cart_controller.js` Stimulus |
| Checkout | Embedded Stripe Payment Element; `CheckoutsController`; Stimulus `checkout_controller.js`; `POST /checkout` returns `clientSecret`/`orderId`; confirmation page marks order paid + wipes cart |
| Digital Downloads | `has_many_attached :download_files` on Product; `DownloadsController` serving signed blob URLs; `ProductPolicy#download?` purchase gate; `/account/downloads` page; `ActiveStorageMultiField` Administrate custom field |
| Refunds & Revenue | `Admin::OrdersController#refund` one-click Stripe refund; custom order show with status pill + formatted money; `Admin::RevenueController` monthly stats via PostgreSQL `DATE_TRUNC`; `LineItemDashboard`; `StripeHelper#with_stripe_refund` |
| Email Notifications | `Administrate::Punditize` wired; `CategoryPolicy`; explicit authorize on `Admin::UsersController` + `Admin::MediaController` overrides; FriendlyId `find_resource` in `Admin::PagesController` + `Admin::PostsController`; `OrderMailer` (confirmation/download_ready/refund_receipt); idempotent `SendOrderConfirmationJob` + `SendRefundReceiptJob`; 26 new tests |
| Tests | **444 runs, 1110 assertions, 0 failures**; Minitest throughout; `StripeHelper` with `with_stripe_payment_intent` + `with_stripe_refund` |

---

## Phase 1 — Content & Media Foundation
**Goal:** Give editors a complete toolbox for all media types before any feature builds
on top of it. Everything in later phases depends on rich media working reliably.

### ~~1.1 Media Manager~~ ✅ Done
- `Medium` model: polymorphic owner, file type enum (image/audio/video/document), 200 MB cap, content-type allow-list
- Admin media library: grid view, filter tabs, search, Pagy pagination (24/page), bulk-delete
- Drag-and-drop multi-file upload via Stimulus + Fetch API
- Pundit policy: editor can upload/edit; admin-only delete
- 30 new tests (15 model + 15 integration); full suite now 63 runs / 213 assertions / 0 failures

### ~~1.2 Audio Player~~ ✅ Done
- Stimulus `audio_player_controller.js`: play/pause, seek scrubber with CSS gradient progress, volume, speed (0.5×–2×), aria-label/aria-pressed
- Shared partial `app/views/shared/_audio_player.html.erb`: accepts any `Medium` + `show_download` option
- Wired into admin media show page for audio files; 10 integration tests

### ~~1.3 Video Player~~ ✅ Done
- Stimulus `video_player_controller.js`: play/pause, scrubber, volume, speed, screen-click, fullscreen (container-level with video fallback)
- Shared partial `app/views/shared/_video_player.html.erb`: accepts `poster_url` + `show_download` locals
- Wired into admin media show page; AVI re-encode FFmpeg instructions in README; 12 integration tests

### ~~1.4 Third-Party Embed Widgets~~ ✅ Done
- `EmbedParser` PORO: YouTube (watch/youtu.be/playlist), Vimeo, Spotify (track/album/playlist/artist), SoundCloud, Apple Music
- Shared `_embed.html.erb` partial: 16:9 ratio container or fixed-height iframe by provider
- `Admin::EmbedsController#preview` — GET `/admin/embeds/preview?url=URL`; editor/admin only
- Stimulus `embed_picker_controller`: "Embed" button in Trix toolbar → URL input → live preview panel
- CSP enabled: `frame-src` enforced; nonce-based `script-src` with `strict-dynamic`
- 32 new tests (24 unit + 8 integration)

### ~~1.5 Blog System Enhancements~~ ✅ Done
- ~~Pagination~~ ✅ (Phase 1.5 precursor)
- `Post#reading_time` (words ÷ 200, min 1); displayed in post byline
- Related posts: up to 3 live posts sharing categories, rendered below body
- RSS 2.0 feed at `/feed.xml` (20 posts, public, no auth)
- `Series` model (FriendlyId, ordered posts); `belongs_to :series` on Post; `/series/:slug` public route + landing page; admin dashboard
- Draft preview: already handled by `PostPolicy#show?` — no extra work needed

---

## Phase 2 — User Accounts & Profiles
**Goal:** Expand auth into a real membership system. Required foundation for forums,
purchases, and download gating.

### ~~2.1 User Profile~~ ✅ Done
- `bio` (text, 280 chars) + `website_url` (http/https) added to users; `avatar` via Active Storage
- Public profile page at `/members/:display_name` (case-insensitive lookup, 404 on miss)
- Settings page at `/settings`: profile form + password change; Pundit-gated; "Sign in" / "Settings" in header
- 38 new tests (15 model + 23 integration); full suite: 178 runs / 488 assertions / 0 failures

### ~~2.2 Self-Service Registration~~ ✅ Done
- `RegistrationsController`: `GET/POST /register` (invite-only gate, role-locked to member), `GET /register/verify?token=` (48h expiry, auto-sign-in), `POST /register/resend` (enumeration-safe)
- `SiteSetting` model: typed get/set/invite_only? API with DEFAULTS; `site_settings` table
- `SendEmailVerificationJob` + `UserMailer#email_verification` (HTML + text)
- Hard block in `SessionsController#create` for unverified users
- `Admin::SiteSettingsController`: admin-only invite_only toggle at `/admin/settings`
- Auth layout CSP nonce; Administrate nav "Site Settings" link
- 42 new tests (14 model + 28 integration); full suite: 220 runs / 592 assertions / 0 failures

### ~~2.3 User Roles Expansion~~ ✅ Done
- `member` (3): self-registered public user; can sign in, browse, buy (Phase 3), comment (Phase 4); no editorial or admin access
- `subscriber` (4): paid member (promoted in Phase 3); same as member + access to `requires_subscriber` content
- `User#admin_accessible?` and `#content_creator?` helpers on the model
- `ApplicationPolicy` private helpers: `admin_accessible?`, `content_creator?`, `subscriber_or_above?`
- `PostPolicy`: `create?` restricted to content creators; `show?` + `Scope` gate subscriber posts behind `requires_subscriber` flag
- `PagePolicy`: `index?/create?/update?` tightened to `admin_accessible?`
- Migration: `posts.requires_subscriber boolean NOT NULL DEFAULT false`; `PostDashboard` updated
- 38 new tests (23 model + 15 integration); full suite: 258 runs / 649 assertions / 0 failures

### ~~2.4 User Administration~~ ✅ Done
- `banned_at` on User; `ban!`/`unban!`; SessionsController blocks banned users with identical error (no enumeration)
- `ImpersonationLog` model; `impersonator_session_id` stores admin session ID in DB for reliable restore
- `Admin::ImpersonationsController < ::ApplicationController` (root prefix prevents member exit being blocked by `authorize_admin_access`)
- Impersonation banner in layout; audit log on admin user show page
- Bulk role assignment (`PATCH /admin/users/bulk_role`, Pundit-gated to admin)
- Custom admin user index (search, role/status badges, bulk-role form) and show page
- `UserPolicy`: `ban?`, `unban?`, `impersonate?` (admin only, cannot target another admin), `bulk_role?`
- 28 new tests (23 integration + 5 model); full suite: 286 runs / 732 assertions / 0 failures

---

## Phase 3 — E-Commerce & Payments
**Goal:** Full Stripe integration for one-off purchases, a shopping cart, and digital
download delivery. Required by the Album Manager in Phase 6.

### ~~3.1 Stripe Integration~~ ✅ Done
- `stripe` gem (13.5.1); `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` stored as Railway env vars; `config/initializers/stripe.rb`
- `StripeWebhooksController`: handles `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`; HMAC-verified via `Stripe::Webhook.construct_event`; CSRF-exempt; `allow_unauthenticated_access`
- Models: `Product` (FriendlyId, status enum, polymorphic productable, `active_price`, `format_money`), `Price`, `Order` (optional user, email normalization), `LineItem`, `StripeCustomer`
- Pundit policies: `ProductPolicy`, `PricePolicy`, `OrderPolicy`
- Administrate dashboards: `ProductDashboard`, `PriceDashboard`, `OrderDashboard`; admin routes: `resources :products`, `resources :orders, only: %i[index show]`
- Webhook tests use `define_singleton_method` to replace `Stripe::Webhook.construct_event` (Minitest 6 removed `#stub`)
- 48 new tests (8 integration + 40 model); full suite: 334 runs / 822 assertions / 0 failures

### ~~3.2 Shop~~ ✅ Done
- Public shop index at `/shop` — product grid with price, cover image, description
- Product show page with "Add to cart" and "Buy it now" buttons
- Admin product management dashboard (CRUD, stock toggle, image, description, price)

### ~~3.3 Shopping Cart~~ ✅ Done
- Session-based cart (anonymous or authenticated)
- Cart drawer (Turbo Frame, slides in from right)
- Line item quantity update and remove
- Cart persists to DB on login, merges anonymous + authenticated carts

### ~~3.4 Checkout~~ ✅ Done (commit `3dd7c24`)
- Embedded Stripe Payment Element (in-page — no redirect to Stripe-hosted page)
- `CheckoutsController`: `new` (GET, redirects on empty cart), `create` (POST JSON — builds Order + LineItems, creates Stripe PaymentIntent, returns `{clientSecret, orderId}`), `confirmation` (GET — retrieves PI status, marks order paid, wipes cart)
- Stimulus `checkout_controller.js`: validates email, POSTs for `clientSecret`, mounts Payment Element, calls `stripe.confirmPayment({ redirect: "if_required" })`
- Two-column responsive layout (payment form + order summary sidebar)
- 13 integration tests in `test/integration/checkout_test.rb`; full suite: **386 runs, 954 assertions**

### ~~3.5 Digital Downloads~~ ✅ Done (commit `c727281`)
- `Product` gets `has_many_attached :download_files` — no migrations needed (Active Storage)
- `ProductPolicy#download?`: admins/editors always allowed; regular users need a paid `Order` containing the product via `LineItem`
- `DownloadsController`: `index` lists purchased products with download files; `show` serves blob via signed ID → `ActiveStorage::Attachment` bridge → Pundit authorize → `rails_blob_path(blob, disposition: "attachment")`
- User download history at `/account/downloads`
- `ActiveStorageMultiField` Administrate custom field: `self.permitted_attribute` returns `{ attr => [] }` for `has_many_attached` strong-params support
- 12 integration tests in `test/integration/downloads_test.rb`; full suite: **398 runs, 986 assertions**

### ~~3.6 Refunds & Admin Order Management~~ ✅ Done (commit `56ab9a6`)
- `Admin::OrdersController#refund` (POST `member { post :refund }`): guards `paid?` status, calls `Stripe::Refund.create(payment_intent:)`, marks order `:refunded`; rescues `Stripe::StripeError` with flash alert
- Custom `app/views/admin/orders/show.html.erb`: status pill badge (CSS class per status), "Issue Full Refund" button (admin + paid only, `turbo_confirm`), `total_display` formatted money
- `Admin::RevenueController#show`: monthly stats via `DATE_TRUNC('month', created_at)` grouped by month+currency (last 12 months); all-time totals by currency; `RevenuePolicy#show?` (editor/admin)
- Revenue link in admin navigation for editor/admin
- `LineItemDashboard` created (required by `OrderDashboard`'s `Field::HasMany :line_items`)
- `StripeHelper#with_stripe_refund` added; 11 refund tests + 9 revenue tests; full suite: **418 runs, 1040 assertions**

### ~~3.7 Email Notifications~~ ✅ Done (commits `f0ba7d7`, `9f28005`)
- `Administrate::Punditize` included in `Admin::ApplicationController` — standard CRUD methods auto-enforce Pundit `policy_scope!` / `authorize`
- `CategoryPolicy` added; explicit `authorize` added to `Admin::UsersController` and `Admin::MediaController` custom overrides; FriendlyId `find_resource` fixed in `Admin::PagesController` and `Admin::PostsController`
- `OrderMailer#confirmation(order)` — itemised receipt; triggered from `CheckoutsController#confirmation` and `StripeWebhooksController#handle_payment_intent_succeeded` via `SendOrderConfirmationJob`
- `OrderMailer#download_ready(order)` — sent alongside confirmation when order contains products with `download_files`; links to `/account/downloads` for users
- `OrderMailer#refund_receipt(order)` — sent from `Admin::OrdersController#refund` after successful Stripe refund via `SendRefundReceiptJob`
- Both jobs idempotent via `Order.where(id:, *_sent_at: nil).update_all(...)` atomic claim (prevents double-delivery from webhook + controller race)
- Migration: `confirmation_email_sent_at`, `refund_receipt_sent_at` nullable datetime columns on `orders`
- HTML + text templates for all three actions
- 26 new tests: `test/mailers/order_mailer_test.rb`, `test/mailers/user_mailer_test.rb`, `test/mailers/passwords_mailer_test.rb`, `test/jobs/send_order_confirmation_job_test.rb`, `test/jobs/send_refund_receipt_job_test.rb`, `test/jobs/send_email_verification_job_test.rb`
- Full suite: **444 runs, 1110 assertions, 0 failures**
- **Remaining:** Set `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` Railway env vars — email code is complete but delivery is silent until SMTP is configured

---

## Phase 4 — Community & Forum  — **NEXT PHASE**
**Goal:** Add a community discussion layer that is styleable independently of the main
site and can be set to public, members-only, or subscriber-only per section.

### 4.1 Core Forum Models
- `Forum` (category bucket), `Thread`, `Reply`
- `Forum` has: name, description, slug, visibility enum (`public`, `members`, `subscribers`), position, icon
- `Thread` has: title, body (Action Text), author, pinned, locked, view count, reply count, last-reply-at
- `Reply` has: body (Action Text), author, likes count, is_solution flag

### 4.2 Forum UI
- Forum index at `/community`
- Thread list per forum, paginated (Pagy)
- Thread show with threaded or flat replies (admin toggle)
- New thread and reply forms with Turbo Streams (no full reload)
- Markdown or Trix body for replies (admin setting per forum)

### 4.3 Reactions & Moderation
- `Like` model: polymorphic (Thread or Reply), one-per-user enforcement
- Flag / report post → notifies admin, queued for review
- Admin moderation queue: approve, remove, ban author
- Thread lock and pin controls on thread show page (editor/admin only)

### 4.4 Notifications
- `Notification` model: type, actor, recipient, notifiable (polymorphic)
- Notify thread author when someone replies
- Notify reply author when their reply is liked
- Notification bell in site header with unread count (Turbo Streams)

### 4.5 Community Design Customisation
- Per-forum accent colour (stored in Forum, applied via CSS custom property on container)
- Cover image and custom header per forum
- Admin can set global community layout: `classic`, `reddit`, `discord-flat`

---

## Phase 5 — Admin Group Chat
**Goal:** Give the admin team a private, real-time Discord-style communication channel
without leaving the CMS. For coordination, feedback on drafts, and release planning.

### 5.1 Chat Models
- `ChatChannel` (name, description, is_private, created_by)
- `ChatMessage` (channel, author, body, attachment via Active Storage, edited_at)
- `Reaction` (message, user, emoji — Unicode codepoint string)

### 5.2 Real-Time with ActionCable
- `ChatChannel` broadcasts on `ChatChannel::STREAM_NAME`
- Turbo Streams deliver new messages and reaction updates instantly
- Typing indicator: broadcast ephemeral "X is typing..." with a 3 s auto-expire

### 5.3 UI
- Admin sidebar channel list (left rail, Discord-style)
- Message feed with avatar, display name, timestamp, body, attachments
- Emoji picker (use `emoji-mart` or a lightweight inline Unicode table)
- Reaction chips below each message; click to toggle your reaction
- Edit and delete own messages (soft delete, "message removed" placeholder)
- File/image drop zone in composer

### 5.4 Access Control
- Only `admin` and `editor` roles can access chat
- Per-channel `is_private` restricts to `admin` only
- Audit log: every message is immutably stored even if soft-deleted

---

## Phase 6 — Album Manager
**Goal:** A full music-project management tool inside the CMS that takes an album from
first track upload through collaborative review to published-and-for-sale.

### 6.1 Album Model
- `Album`: title, artist, artwork (Active Storage), description, release_date, status enum (`draft`, `in_review`, `mastered`, `published`), genre, label, UPC
- `Track`: album, title, audio (Active Storage), position, duration_seconds, lyrics (Action Text), credits (text), ISRC, preview_start_seconds, preview_end_seconds
- `AlbumCollaborator`: album, user, role (`producer`, `engineer`, `artist`, `manager`)

### 6.2 Collaboration Workspace (Admin)
- Album dashboard at `/admin/albums` — kanban-style status columns
- Track list with drag-to-reorder (Stimulus + Sortable.js)
- Per-track inline audio player so collaborators can listen without downloading
- Per-track comment thread (reuses `Reply` model with `commentable` polymorphism)
- Version history: re-upload a track creates a new `TrackVersion`; previous versions retained
- Album cover artwork crop tool (CSS crop with coordinates saved to DB)

### 6.3 Publishing Pipeline
- Admin "Publish Album" button: validates all tracks have audio, artwork is set, release_date is set
- Sets status to `published`, creates a public `Page` stub if none exists, syncs `Product` for sale
- Public album page at `/albums/:slug` with tracklist, artwork, embed player, buy button
- Individual track preview player (plays `preview_start` → `preview_end` only for non-buyers)

### 6.4 Sales & Downloads
- Album can be sold as a full bundle (ZIP of all tracks) or per-track
- Reuses Phase 3 `Product` / `Order` / `Download` infrastructure
- Verified buyer gets access to full WAV or MP3 files via signed download URLs
- Admin download report: who downloaded which tracks, when

---

## Phase 7 — Claude AI Assistant
**Goal:** Embed a Claude-powered assistant in the admin panel to accelerate content
creation, answer editorial questions, and automate repetitive CMS tasks.

### 7.1 Integration
- `Anthropic` Ruby gem (or direct HTTP via `Faraday`)
- Store `ANTHROPIC_API_KEY` as Railway env var — never committed to repo
- `AiConversation` and `AiMessage` models for conversation history persistence

### 7.2 Admin AI Tab
- Dedicated `/admin/ai` route, accessible to `editor` and `admin`
- Chat interface (Turbo Streams for streaming responses)
- Conversation history sidebar with ability to start new sessions

### 7.3 Capabilities
- **Q&A:** answer general questions about the CMS or the publishing industry
- **Page drafting:** "Draft a home page about X" → returns Action Text-compatible HTML
- **Post drafting:** "Write a blog post about our new album" → prefills the Post form
- **Media alt text:** given an attached image, suggest accessible alt text
- **SEO suggestions:** given a page/post, suggest meta title and description
- **Bulk operations:** "List all draft posts older than 30 days" via a structured query

### 7.4 Guardrails
- System prompt restricts assistant to CMS-related tasks
- All API calls logged in `AiMessage` with token counts
- Token budget alert if monthly spend approaches a configurable threshold

---

## Phase 8 — Plugin System
**Goal:** Allow third-party developers (or the VybeDeck team) to extend the CMS
without forking the core application.

### 8.1 Plugin SDK
- Define a Ruby module `VybeDeck::Plugin::Base` with lifecycle hooks:
  - `on_install`, `on_activate`, `on_deactivate`, `on_uninstall`
  - View hooks: `inject_head`, `inject_footer`, `inject_admin_sidebar`
  - Model hooks: `after_post_publish`, `after_order_complete`
- SDK published as a separate gem `vybedesk-plugin-sdk`
- Plugin manifest file: `vybedeckplugin.json` (name, version, author, hooks declared)

### 8.2 Plugin Registry
- `Plugin` model: name, slug, version, status enum (`installed`, `active`, `disabled`)
- Admin plugins list at `/admin/plugins`: install from file upload or git URL
- Plugin settings page (plugin declares its own settings schema; CMS renders the form)

### 8.3 Sandbox & Security
- Plugins run in a restricted Ruby environment (no `eval`, no `Kernel.system`)
- File-system access restricted to a per-plugin storage directory
- Outbound HTTP allowed only to declared `allowed_hosts` in manifest
- Code review requirement documented in `CONTRIBUTING.md` for any core hook

---

## Phase 9 — Visual Design System Builder
**Goal:** Allow admins to customise the site's look without writing CSS, while giving
power users full CSS variable access.

### 9.1 Theme Model
- `Theme`: name, is_active, token overrides stored as JSON (maps CSS variable names to values)
- Only one theme active at a time; active theme tokens are server-rendered into `<style>` in `<head>`

### 9.2 Theme Editor UI
- Admin theme editor at `/admin/theme`
- Live preview pane (iframe of public site, refreshes on token change)
- Token groups: Colours, Typography, Radius, Spacing, Shadows
- Colour pickers for all `--bg`, `--text`, `--accent` family variables
- Radius slider for `--radius-sm` / `--radius` / `--radius-lg`
- Font family picker (Google Fonts or system fonts)
- Export theme as JSON; import JSON to restore

### 9.3 Per-Section Theming
- Individual `Forum`, `Album`, `Shop` sections can override accent colour and background
- Section theme is applied via a scoped `data-section-theme` attribute

---

## Phase 10 — SEO & Discoverability
**Goal:** Every public page is optimised for classic search and AI answer engines.
*(Deferred until all features are implemented, per owner instruction.)*

- ~~`<meta name="description">` from `Seoable#meta_description`~~ ✅ Done — output wired via layout `content_for(:description)`
- Wire `Seoable` to also output canonical `<link>` tag
- Open Graph and Twitter Card meta tags on pages and posts
- JSON-LD structured data: `Article`, `MusicAlbum`, `Product`, `BreadcrumbList`
- Sitemap at `/sitemap.xml` auto-generated by Solid Queue job (daily)
- `robots.txt` managed via admin UI
- GEO (AI answer engine optimisation): FAQ blocks, statistics density, entity markup

---

## Cross-Cutting Concerns (apply to every phase)

| Concern | Requirement |
|---------|-------------|
| **Tests** | Every new model, controller, and service gets tests. 85% line coverage minimum per PR. |
| **Security** | No credentials committed. Every new controller action gets a Pundit policy check. |
| **Performance** | Pagy for any list. Counter caches for counts. N+1 queries caught with Bullet in dev. |
| **Background jobs** | Solid Queue handles all email, image processing, sitemap builds, AI calls. |
| **Active Storage** | Switch to S3-compatible storage before Phase 3 (local volume is not durable in containers). |
| **Image processor** | Add `libvips` to Dockerfile before processing variants in production. |
| **Design system** | All new UI uses existing CSS custom properties. No new hard-coded colours or fonts. |
| **Accessibility** | ARIA roles on interactive components. Focus states visible. Colour contrast AA minimum. |

---

## Dependency Tree

```
Phase 1 (Media)
  └── Phase 2 (Users)
        ├── Phase 3 (E-Commerce)
        │     └── Phase 6 (Album Manager) ← also needs Phase 1
        ├── Phase 4 (Community)
        └── Phase 5 (Admin Chat)
Phase 7 (AI) — independent, can start after Phase 1
Phase 8 (Plugins) — start after Phase 3 so plugin hooks cover commerce
Phase 9 (Design Builder) — independent
Phase 10 (SEO) — last; after all public surfaces exist
```

---

## Tech Decisions Already Made (do not reverse without discussion)

- **Page ≠ Post.** Never combine with STI or a `type` column.
- **Pundit, not CanCanCan.** All new authorisation goes in Pundit policies.
- **Minitest, not RSpec.** Do not migrate the suite.
- **Propshaft, not Sprockets.** CSS `@import` is browser-resolved, not bundled.
- **No Redis.** Solid Queue / Cache / Cable for all async needs.
- **Rails auth, not Devise.** Extend the generated controller pattern; do not add Devise.
- **Stripe, not PayPal.** Only one payment processor in scope.
- **Anthropic / Claude, not OpenAI.** Phase 7 AI integration uses `anthropic` SDK.
