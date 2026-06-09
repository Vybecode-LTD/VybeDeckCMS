# AGENTS.md — VybeDeck CMS

> Project context for Codex and AGENTS.md-compatible agents.
> New sessions read this file first, then `CLAUDE.md` and `HANDOFF.md`.
> Keep "Last Completed Task" and "Active Task" current at the end of every session.

---

## Last Completed Task

**Phase 3.7 — Email Notifications** (commits `f0ba7d7`, `9f28005`, 2026-06-09):
`Administrate::Punditize` wired into `Admin::ApplicationController`; `CategoryPolicy` created; explicit `authorize` calls added to `Admin::UsersController` and `Admin::MediaController` (custom overrides bypass Punditize); FriendlyId `find_resource` fixes in `Admin::PagesController` and `Admin::PostsController`. `OrderMailer` with `confirmation`, `download_ready`, and `refund_receipt` actions; idempotent `SendOrderConfirmationJob` and `SendRefundReceiptJob` (atomic `update_all` lock); HTML + text templates; wired into `CheckoutsController#confirmation`, `StripeWebhooksController#handle_payment_intent_succeeded`, and `Admin::OrdersController#refund`. 26 new tests. Full suite: **444 runs, 1110 assertions, 0 failures**.

## Active Task

**Phase 4 — Community & Forum** (not yet started):
`Forum`, `Thread`, `Reply` models; public `/community` routes; Turbo Stream reply posting; reactions and moderation queue; notification bell in site header. **Pre-requisite:** Set `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` as Railway env vars before Phase 4 starts — all transactional email code is in place but SMTP is not yet activated in production.

---

## Overview

VybeDeck CMS is a Rails 8.1 monolith and database island. It is a full-featured creative-industry publishing and e-commerce platform targeting music labels, artists, and creative agencies. It has its own PostgreSQL database, its own authentication, a public Hotwire site, an Administrate admin panel, and a Stripe-powered shop with digital downloads.

**Do not** share this database with another app. **Do not** add Devise. **Do not** add React. **Do not** add Redis.

---

## Architecture

- **Framework:** Rails 8.1, Ruby 3.4
- **Database:** PostgreSQL 17 (primary). Solid Queue, Solid Cache, and Solid Cable all share the same `DATABASE_URL` connection in production (Railway single-Postgres constraint). No separate queue/cache databases.
- **No Redis.** Solid trio handles all async needs.
- **Asset pipeline:** Propshaft (not Sprockets). CSS `@import` is browser-resolved, not bundled.
- **JavaScript:** Importmap + Stimulus. No Webpack, no Node build step.
- **Public site:** Server-rendered Hotwire/Turbo. No React frontend.
- **Admin panel:** Administrate 1.0, namespace `admin/`.
- **Auth:** Rails 8 generated authentication (`SessionsController`, `PasswordsController`, token-based `Session` model).
- **Authorisation:** Pundit policies on every controller action. No shortcuts that bypass policy classes.
- **Payments:** Stripe only (`stripe` gem 13.5.1). Embedded Payment Element (no Stripe-hosted redirect).
- **File storage:** Active Storage. Local disk in development. Production switches to S3 (`:amazon`) when `AWS_BUCKET` env var is set.
- **Deployment:** Railway PaaS — auto-deploys from `main` via Dockerfile. Not Kamal. Not VPS.
- **AI integration:** Phase 7+ will use Anthropic/Claude. Not OpenAI.

### User Roles (integer enum on `User#role`)

| Value | Name | Description |
|-------|------|-------------|
| 0 | `author` | Content creator — can create/edit/publish posts |
| 1 | `editor` | Content creator + admin panel access (non-destructive) |
| 2 | `admin` | Full access — ban, impersonate, refunds, site settings |
| 3 | `member` | Self-registered public user — can sign in, buy, download |
| 4 | `subscriber` | Paid member — member access + subscriber-only content |

Self-registration defaults to `member`. Promotion to higher roles is admin-only.

---

## Content Rules

- `Page` and `Post` are **separate models and separate tables**. Never merge with STI or a `type` column.
- Shared publishing/SEO behaviour lives in `Publishable` and `Seoable` concerns.
- Slugs use FriendlyId with slug history.
- Active Storage variants are backgrounded — **never call `.processed` in a request context** (it will block).
- All new UI uses the existing CSS custom properties from `application.css`. No hard-coded colours or fonts.

---

## Build, Test, Run

Use this PATH prefix in PowerShell first:

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms
```

Then:

```powershell
ruby bin\rails test          # expected: 444 runs, 1110 assertions, 0 failures
ruby bin\rails db:seed       # idempotent — safe to run anytime
ruby bin\rails server        # dev server on :3000
```

---

## Current Branch State

- **Branch:** `main`
- **Last commit:** `9f28005` — Phase 3.7 Email Notifications + test/security remediation
- **Remote:** `https://github.com/Vybecode-LTD/VybeDeckCMS.git`
- All Phase 1, 2, and 3 work is committed and on `main`. Nothing pending.

---

## Completed Phase History

| Phase | Commit | Summary |
|-------|--------|---------|
| Foundation | `9ef92be` | Rails 8, auth, Pundit, Page/Post/Category, Administrate, public site, design system, Railway |
| 1.1 Media Manager | `06a7d2f` | `Medium` model, admin grid, drag-drop upload |
| 1.2 Audio Player | `44b5b56` | Stimulus audio controller, shared partial |
| 1.3 Video Player | `088e824` | Stimulus video controller, fullscreen |
| 1.4 Embed Widgets | `950a827` | EmbedParser PORO, CSP, Trix embed picker |
| 1.5 Blog Enhancements | `f906f4b` | Reading time, related posts, RSS feed, Series model |
| 2.1 User Profile | `23cb868` | bio/avatar/website_url, /members, /settings |
| 2.2 Registration | `fc38a88` | Email verification, SiteSetting, invite-only mode |
| 2.3 Roles Expansion | `673e60e` | member + subscriber roles, subscriber-gated posts |
| 2.4 User Admin | `ae2a0f4` | Ban/unban, Login-as impersonation, bulk role assignment |
| 3.1 Stripe Foundation | `e1966ad` | Product/Price/Order/LineItem/StripeCustomer, webhooks |
| 3.2 Public Shop | `4980bf9` | /shop, ShopController, product cards |
| 3.3 Shopping Cart | `a704a09` | Cart/CartItem, session merge, Turbo Stream drawer |
| 3.4 Checkout | `3dd7c24` | Stripe Payment Element, CheckoutsController, Stimulus checkout |
| 3.5 Digital Downloads | `c727281` | has_many_attached download_files, DownloadsController, signed URLs |
| 3.6 Refunds & Revenue | `56ab9a6` | Admin refund action, RevenueController, LineItemDashboard |
| 3.7 Email Notifications | `f0ba7d7`, `9f28005` | Administrate::Punditize, CategoryPolicy, FriendlyId fixes, OrderMailer, SendOrderConfirmationJob, SendRefundReceiptJob, 26 tests |

---

## Gotchas & Hard-Won Knowledge

1. **Minitest 6 removed `Object#stub`.** All Stripe class method replacement uses `define_singleton_method` + `.method()` save/restore in `ensure`. See `test/test_helpers/stripe_helper.rb` for the canonical pattern (`with_stripe_payment_intent`, `with_stripe_refund`).

2. **Rails route pluralization on singular resources.** `resource :revenue` auto-infers `Admin::RevenuesController` (pluralized), not `Admin::RevenueController`. Always add `controller: :revenue` explicitly: `resource :revenue, only: :show, controller: :revenue`.

3. **Cart session capture order on login.** The anonymous `cart_id` must be read from `session[:cart_id]` **before** calling `start_new_session_for` — the session is wiped on login. See `SessionsController#create`.

4. **Administrate `has_many_attached` strong params.** The default `Administrate::Field::Base.permitted_attribute` returns just `attr` (a symbol). For `has_many_attached`, you must override it to return `{ attr => [] }`. See `app/fields/active_storage_multi_field.rb`.

5. **`LineItemDashboard` must exist.** `OrderDashboard` declares `line_items: Field::HasMany`. Administrate looks up `LineItemDashboard` when rendering the order show page. A missing dashboard causes `uninitialized constant LineItemDashboard`.

6. **`Administrate::Field::Base` template lookup.** Custom field templates live at `app/views/fields/<field_type>/` where `field_type = ClassName.to_s.split("::").last.underscore` → `"active_storage_multi_field"` for `ActiveStorageMultiField`.

7. **`require "ostruct"` in Ruby 3.4.** `OpenStruct` is not auto-loaded. `test/test_helpers/stripe_helper.rb` has `require "ostruct"` at the top. All Stripe test doubles are `OpenStruct` instances.

8. **Active Storage `blob.signed_id` vs `blob.id`.** The download controller uses `ActiveStorage::Blob.find_signed!(params[:id])` with the signed ID (from `blob.signed_id`). Do not expose raw blob IDs in URLs.

9. **`Admin::ImpersonationsController < ::ApplicationController`** (root namespace, not `Admin::ApplicationController`). The root prefix is intentional — it prevents members from being blocked by `authorize_admin_access` when they exit an impersonation session.

10. **S3 is not yet active.** `download_files` attachments will be lost on every Railway deploy until `AWS_BUCKET` (and related) env vars are set. Do not add significant production download content before activating S3.

11. **No `libvips` in Dockerfile.** Active Storage variant jobs enqueue but the transforms silently fail in production. Add `RUN apt-get install -y libvips` to `Dockerfile` before relying on image variants.

12. **`Propshaft` + `@import`.** CSS `@import` statements in `application.css` are resolved by the browser, not Propshaft. Do not expect Propshaft to inline/bundle imported files.

---

## Deployment

- **Platform:** Railway PaaS (not Kamal, not a VPS)
- **Auto-deploy:** push to `main` triggers Railway build + deploy
- **`railway.toml`:** `PORT=80` — **CRITICAL, do not remove** (Thruster requires it)
- **`bin/docker-entrypoint`:** runs `db:migrate` with a 12-retry loop before Puma starts
- **All 4 DB configs** (`primary`, `cache`, `queue`, `cable`) share `DATABASE_URL` in production
- **Secrets (Railway env vars only — never commit):**
  - `RAILS_MASTER_KEY`
  - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET`
  - `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_PORT` (optional), `ACTION_MAILER_FROM` (optional) — **REQUIRED: all transactional email code is complete but emails are silent until these are set**
  - `ANTHROPIC_API_KEY` (Phase 7, not yet needed)
