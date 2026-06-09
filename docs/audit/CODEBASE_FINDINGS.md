---
generated: 2026-06-09
auditor: Codex
suite_result: "PASS: 418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips; PowerShell command exited 1 because Ruby emitted a Fiddle/reline warning on stderr"
---

# Codebase Findings

Paths are relative to `C:\DEV\VybeDeck\vybedeck_cms` unless noted.

## Test Run

✅ PASS: `418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips`.

Matches documented baseline: yes.

No test failures or errors occurred. PowerShell process status was nonzero because Ruby printed this warning after the green run:

```text
ruby : C:/DEV/VybeDeck/.tools/Ruby34/lib/ruby/gems/3.4.0/gems/reline-0.6.3/lib/reline/io/windows.rb:1: warning:
C:/DEV/VybeDeck/.tools/Ruby34/lib/ruby/3.4.0/fiddle/import.rb is found in fiddle, which will no longer be part of the default gems starting from Ruby 4.0.0.
```

## Architecture Compliance

| Rule | Result | Evidence |
|---|---:|---|
| Page and Post are separate, no STI/type column | ✅ PASS | `app/models/page.rb:1`, `app/models/post.rb:1`, `db/schema.rb:154-168`, `db/schema.rb:170-189`; no `type` column found in either table. |
| Pundit on every action | 🟠 HIGH | Public/content actions mostly use `authorize` or `policy_scope`, but several custom admin/auth/cart actions do not. Admin base has broad `authorize :admin, :access?` only: `app/controllers/admin/application_controller.rb:38`. |
| No secrets in repo | 🟡 MEDIUM | No hardcoded API keys found. `config/credentials.yml.enc` is tracked; `config/master.key` exists locally but is ignored and untracked. Evidence: `.gitignore:34`, `git ls-files` only returned `config/credentials.yml.enc`. |
| No Devise | ✅ PASS | `Gemfile` has Rails auth dependencies but no Devise; `bcrypt` at `Gemfile:29`. |
| Minitest only | ✅ PASS | No `rspec`/`rspec-rails` in `Gemfile`; tests are under `test/`. |
| No Redis | ✅ PASS | Solid trio gems present: `Gemfile:35-37`; no Redis gem found. |
| No React | ✅ PASS | Importmap/Hotwire/Stimulus present: `Gemfile:18-22`; no `package.json`, React, Vite, or Webpack config found. |
| Propshaft, not Sprockets | ✅ PASS | `Gemfile:9-10`; no Sprockets dependency found. |
| Stripe only | ✅ PASS | `Gemfile:79`, `config/initializers/stripe.rb:3`; no PayPal/Braintree gems found. |

## Pundit Authorization Gaps

🟠 HIGH - Administrate CRUD is not wired to Pundit policies in the app. `Admin::ApplicationController` includes `Pundit::Authorization` but not `Administrate::Punditize` (`app/controllers/admin/application_controller.rb:10`). Administrate default `authorized_action?` returns true unless customized (local gem `C:\DEV\VybeDeck\.tools\Ruby34\lib\ruby\gems\3.4.0\gems\administrate-1.0.0\app\controllers\administrate\application_controller.rb:254-255`). The Pundit adapter that would call policies exists in the gem but is not included (`...\app\controllers\concerns\administrate\punditize.rb:23-31`). This affects inherited CRUD in:

- `Admin::PagesController` (`app/controllers/admin/pages_controller.rb:2`) despite `PagePolicy#destroy?` being admin-only at `app/policies/page_policy.rb:8`.
- `Admin::PostsController` (`app/controllers/admin/posts_controller.rb:2`).
- `Admin::CategoriesController` (`app/controllers/admin/categories_controller.rb:2`); no `CategoryPolicy` file exists.
- `Admin::ProductsController` (`app/controllers/admin/products_controller.rb:2`) despite `ProductPolicy#destroy?` at `app/policies/product_policy.rb:7`.
- `Admin::OrdersController` inherited `index/show` (`app/controllers/admin/orders_controller.rb:2`); custom `refund` is authorized.

Custom actions with no explicit `authorize`, `policy_scope`, or `skip_authorization`:

| Controller action | Severity | Evidence |
|---|---:|---|
| `Admin::MediaController#index/show/new/create/edit/update/destroy/bulk_destroy` | 🟠 HIGH | Actions at `app/controllers/admin/media_controller.rb:5`, `:12`, `:14`, `:18`, `:30`, `:32`, `:40`, `:45`; `MediumPolicy#destroy?` is admin-only at `app/policies/medium_policy.rb:6`. |
| `Admin::SiteSettingsController#show/update` | 🟡 MEDIUM | Manual admin role guard at `app/controllers/admin/site_settings_controller.rb:3`, no Pundit policy call in actions at `:5`, `:9`. |
| `Admin::UsersController#index/show` | 🟡 MEDIUM | Actions at `app/controllers/admin/users_controller.rb:6`, `:19`; custom ban/unban/impersonate/bulk_role are authorized at `:31`, `:39`, `:47`, `:69`. |
| `Admin::ImpersonationsController#destroy` | 🟡 MEDIUM | Action at `app/controllers/admin/impersonations_controller.rb:9`; relies on current active impersonation lookup, not Pundit. |
| `Admin::EmbedsController#preview` | 🟡 MEDIUM | Action at `app/controllers/admin/embeds_controller.rb:5`; protected only by admin namespace gate. |
| `CartsController#show/update_item/remove_item` | 🟡 MEDIUM | Actions at `app/controllers/carts_controller.rb:5`, `:29`, `:41`; `add_item` authorizes product visibility at `:12`. |
| `CheckoutsController#create` | 🟡 MEDIUM | Action at `app/controllers/checkouts_controller.rb:22`; `new` and `confirmation` call `skip_authorization` at `:15`, `:93`, but `create` does neither. |
| `CategoriesController#show` | 🟢 LOW | Action at `app/controllers/categories_controller.rb:5`; scopes posts at `:7` but does not authorize the category itself. |
| `SeriesController#show` | 🟢 LOW | Action at `app/controllers/series_controller.rb:5`; scopes posts at `:7` but does not authorize `Series`. |
| `FeedController#show` | 🟢 LOW | Action at `app/controllers/feed_controller.rb:4`; intentionally public feed, no explicit `skip_authorization`. |
| `SessionsController#new/create/destroy` | 🟢 LOW | Actions at `app/controllers/sessions_controller.rb:6`, `:9`, `:29`; auth endpoints normally do not use Pundit but the architecture rule says every action. |
| `PasswordsController#new/create/edit/update` | 🟢 LOW | Actions at `app/controllers/passwords_controller.rb:7`, `:10`, `:18`, `:21`. |
| `RegistrationsController#new/create/verify_email/resend_verification` | 🟢 LOW | Actions at `app/controllers/registrations_controller.rb:10`, `:14`, `:31`, `:56`. |
| `StripeWebhooksController#create` | 🟢 LOW | Public signed webhook at `app/controllers/stripe_webhooks_controller.rb:9`; signature verified at `:13-15`. |

## Broken Wiring

🟡 MEDIUM - Admin Series route points to a missing controller. `config/routes.rb:27` declares `resources :series`; `app/dashboards/series_dashboard.rb:3` exists; `app/controllers/admin/series_controller.rb` does not. No admin series integration test was found (`rg admin_series` returned none).

## Known Gaps Status

| Gap | Status | Evidence |
|---|---:|---|
| No order confirmation/download/refund emails | Confirmed | `app/mailers/order_mailer.rb` is missing; no order mailer templates/jobs found. |
| S3 not active | Confirmed | Amazon service exists at `config/storage.yml:11-16`; production only switches when `AWS_BUCKET` is present at `config/environments/production.rb:25`; `aws-sdk-s3` is in `Gemfile:78`. |
| SMTP not active | Confirmed | SMTP delivery config is conditional on `ENV["SMTP_ADDRESS"]` at `config/environments/production.rb:57-68`. |
| No libvips in Dockerfile | Resolved / different than docs | Dockerfile installs `libvips` in runtime and build stages: `Dockerfile:19`, `Dockerfile:35`. |
| Seoable no validators | Confirmed | `app/models/concerns/seoable.rb:1-3` contains only an empty concern; no `validates` calls. |

## Production Readiness

| File | Result | Finding |
|---|---:|---|
| `Dockerfile` | ✅ PASS | Sets production env at `Dockerfile:24`, installs `libvips` at `:19` and `:35`, precompiles assets at `:61`. |
| `railway.toml` | ✅ PASS | `PORT = "80"` at `railway.toml:12`; `healthcheckTimeout = 600` at `:6`. |
| `bin/docker-entrypoint` | ✅ PASS | `db:migrate` retry loop uses `retries=12` at `bin/docker-entrypoint:7-8`. |
| `config/database.yml` | ✅ PASS | `primary/cache/queue/cable` inherit `DATABASE_URL` in production at `config/database.yml:93-106`. |
| `config/environments/production.rb` | ✅ PASS with external dependency | `force_ssl` true at `:29`, `log_level` env/default info at `:37`, Active Storage conditional at `:25`, SMTP conditional at `:57-68`. |
| `config/initializers/stripe.rb` | ✅ PASS | Reads `ENV["STRIPE_SECRET_KEY"]` at `config/initializers/stripe.rb:3`; no hardcoded key. |

## Test Coverage Snapshot

Model direct unit-test status:

| Model file | Test file | Status |
|---|---|---:|
| `app/models/application_record.rb` | none | Not directly tested |
| `app/models/cart.rb` | `test/models/cart_test.rb` | Present, 12 tests |
| `app/models/cart_item.rb` | `test/models/cart_item_test.rb` | Present, 4 tests |
| `app/models/category.rb` | `test/models/category_test.rb` | File exists, 0 tests |
| `app/models/concerns/publishable.rb` | public/admin integration tests | No direct concern test |
| `app/models/concerns/seoable.rb` | `test/integration/public_cms_routes_test.rb` | Integration only |
| `app/models/current.rb` | none | Not directly tested |
| `app/models/embed_parser.rb` | `test/models/embed_parser_test.rb` | Present, 21 tests |
| `app/models/impersonation_log.rb` | `test/models/impersonation_log_test.rb` | Present, 4 tests |
| `app/models/line_item.rb` | `test/models/line_item_test.rb` | Present, 5 tests |
| `app/models/medium.rb` | `test/models/medium_test.rb` | Present, 15 tests |
| `app/models/order.rb` | `test/models/order_test.rb` | Present, 10 tests |
| `app/models/page.rb` | `test/models/page_test.rb` | File exists, 0 tests |
| `app/models/post.rb` | `test/models/post_test.rb` | Present, 6 tests |
| `app/models/price.rb` | `test/models/price_test.rb` | Present, 6 tests |
| `app/models/product.rb` | `test/models/product_test.rb` | Present, 15 tests |
| `app/models/series.rb` | `test/integration/blog_enhancements_test.rb` | Integration only |
| `app/models/session.rb` | session controller tests | No direct model test |
| `app/models/site_setting.rb` | `test/models/site_setting_test.rb` | Present, 13 tests |
| `app/models/stripe_customer.rb` | `test/models/stripe_customer_test.rb` | Present, 4 tests |
| `app/models/tagging.rb` | `test/models/tagging_test.rb` | File exists, 0 tests |
| `app/models/user.rb` | `test/models/user_test.rb`, `test/models/user_profile_test.rb` | Present, 42 combined tests |

Security concerns found:

- 🟠 HIGH - Admin resource policy integration is incomplete, described above.
- 🟡 MEDIUM - `config/master.key` exists locally. It is ignored and not tracked, but the prompt requested that `credentials.yml.enc` be the only credentials file; treat this as local hygiene to verify before sharing the workspace. Evidence: `.gitignore:34`, `git ls-files` only returned `config/credentials.yml.enc`.
- 🟡 MEDIUM - Production downloads are not durable until S3 env vars are set.
- 🟢 LOW - Development/test DB credentials `postgres/postgres` exist in `config/database.yml:28` and `:65`; these are local defaults, not production credentials.
