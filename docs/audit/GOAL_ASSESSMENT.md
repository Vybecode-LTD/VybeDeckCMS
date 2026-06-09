---
generated: 2026-06-09
auditor: Codex
suite_result: "PASS: 418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips; PowerShell command exited 1 because Ruby emitted a Fiddle/reline warning on stderr"
---

# Goal Assessment

Paths are relative to `C:\DEV\VybeDeck\vybedeck_cms`.

## Vision

`ROADMAP.md` states that VybeDeck CMS is a self-hosted creative-industry publishing platform for music labels, independent artists, and creative agencies. Its long-term goal is one deployable Rails 8 monolith for publishing, media management, community, e-commerce, and collaborative album production.

## Completed Phases

| Phase | Goal | What Was Built | Assessment | Evidence |
|---|---|---|---|---|
| 1.1 Media Manager | Editors need an all-media library before later features depend on rich media. | `Medium` model, admin media CRUD/grid, upload Stimulus controller, `MediumPolicy`, tests. | Met with auth gap | `app/models/medium.rb:1`, `app/controllers/admin/media_controller.rb:2`, `app/javascript/controllers/upload_controller.js:3`, `app/policies/medium_policy.rb:1`, `test/models/medium_test.rb:3`, `test/integration/admin_media_test.rb:33`. |
| 1.2 Audio Player | Render custom audio playback for audio media. | Stimulus player and shared partial wired into admin media show, tested. | Met | `app/javascript/controllers/audio_player_controller.js:8`, `app/views/shared/_audio_player.html.erb:8`, `test/integration/audio_player_test.rb:46`. |
| 1.3 Video Player | Render custom video playback with fullscreen support. | Stimulus video player and shared partial, tested. | Met | `app/javascript/controllers/video_player_controller.js:7`, `app/javascript/controllers/video_player_controller.js:80`, `app/views/shared/_video_player.html.erb:10`, `test/integration/video_player_test.rb:57`. |
| 1.4 Embed Widgets | Parse safe third-party media embeds and expose an admin preview/picker. | `EmbedParser`, preview endpoint, picker controller, CSP frame allow-list, tests. | Met with auth gap | `app/models/embed_parser.rb:13`, `app/controllers/admin/embeds_controller.rb:5`, `app/javascript/controllers/embed_picker_controller.js:3`, `config/initializers/content_security_policy.rb:46-51`, `test/models/embed_parser_test.rb:3`, `test/integration/admin_embed_test.rb:50`. |
| 1.5 Blog Enhancements | Add reading time, related posts, RSS, and post series. | `Post#reading_time`, `FeedController`, public series pages, `Series` model/dashboard. | Partially met | `app/models/post.rb:25`, `app/controllers/feed_controller.rb:4`, `app/models/series.rb:1`, `app/dashboards/series_dashboard.rb:3`, `test/integration/blog_enhancements_test.rb:41`; missing `app/controllers/admin/series_controller.rb` despite `config/routes.rb:27`. |
| 2.1 User Profile | Give users profiles and self-service settings. | User `bio`, `website_url`, avatar; public members page; settings/password update. | Met | `app/models/user.rb:6`, `app/models/user.rb:31-47`, `app/controllers/members_controller.rb:5`, `app/controllers/settings_controller.rb:2`, `test/models/user_profile_test.rb:3`, `test/integration/members_and_settings_test.rb:105`. |
| 2.2 Self-Service Registration | Add verified registration with invite-only switch. | Registrations controller, SiteSetting, verification mailer/job, email helpers. | Met | `app/controllers/registrations_controller.rb:14`, `app/models/site_setting.rb:1`, `app/mailers/user_mailer.rb:1`, `app/jobs/send_email_verification_job.rb:1`, `app/models/user.rb:71`, `test/integration/registration_test.rb:16`. |
| 2.3 User Roles Expansion | Add member/subscriber roles and subscriber-gated content. | User enum includes `member`/`subscriber`, `requires_subscriber`, policy helpers and tests. | Met | `app/models/user.rb:13`, `db/schema.rb:177`, `app/policies/application_policy.rb:57-68`, `app/policies/post_policy.rb:14-23`, `test/integration/member_access_test.rb:98`. |
| 2.4 User Administration | Ban/unban, impersonation, audit log, bulk roles. | User ban helpers, `ImpersonationLog`, admin user custom actions, tests. | Met with auth gap | `app/models/user.rb:57-67`, `app/models/impersonation_log.rb:1`, `app/controllers/admin/users_controller.rb:29`, `app/controllers/admin/impersonations_controller.rb:9`, `test/integration/user_administration_test.rb:52`. |
| 3.1 Stripe Foundation | Establish Stripe-backed products, prices, orders, line items, customers, webhooks. | Models, policies, dashboards, Stripe initializer, webhook controller/tests. | Met | `app/models/product.rb:1`, `app/models/price.rb:1`, `app/models/order.rb:1`, `app/models/line_item.rb:1`, `app/models/stripe_customer.rb:1`, `app/controllers/stripe_webhooks_controller.rb:5`, `config/initializers/stripe.rb:3`. |
| 3.2 Public Shop | Public `/shop` and product detail pages. | `ShopController`, `/shop` routes, views, product card, tests. | Met | `config/routes.rb:72-73`, `app/controllers/shop_controller.rb:5`, `app/views/shop/_product_card.html.erb:1`, `test/integration/shop_test.rb:21`. |
| 3.3 Shopping Cart | Session/user cart, drawer, quantity updates, merge on login. | `Cart`, `CartItem`, `CartManagement`, controller, Stimulus controller, tests. | Met with auth gap | `app/models/cart.rb:8`, `app/models/cart_item.rb:6`, `app/controllers/concerns/cart_management.rb:35`, `app/controllers/carts_controller.rb:10`, `app/javascript/controllers/cart_controller.js`, `test/integration/cart_test.rb:27`. |
| 3.4 Checkout | Embedded Stripe Payment Element checkout. | `CheckoutsController`, checkout Stimulus controller, views, tests. | Met with auth gap | `app/controllers/checkouts_controller.rb:22`, `app/controllers/checkouts_controller.rb:56`, `app/javascript/controllers/checkout_controller.js:99`, `app/views/checkouts/new.html.erb`, `test/integration/checkout_test.rb:36`. |
| 3.5 Digital Downloads | Gate downloadable product files by purchase. | Product `download_files`, `DownloadsController`, `ProductPolicy#download?`, custom Administrate field, tests. | Met | `app/models/product.rb:9`, `app/controllers/downloads_controller.rb:25`, `app/policies/product_policy.rb:11`, `app/fields/active_storage_multi_field.rb:5`, `test/integration/downloads_test.rb:91`. |
| 3.6 Refunds & Revenue | Admin refunds and revenue reporting. | Refund action, Stripe refund helper, revenue dashboard/controller/policy/views/tests. | Met | `app/controllers/admin/orders_controller.rb:4`, `app/controllers/admin/orders_controller.rb:13`, `app/controllers/admin/revenue_controller.rb:5`, `app/policies/revenue_policy.rb:3`, `test/integration/admin_refunds_test.rb:37`, `test/integration/admin_revenue_test.rb:53`. |

## Next Phase 3.7 Readiness

Goal: add `OrderMailer#confirmation`, `OrderMailer#download_ready`, `OrderMailer#refund_receipt`, async delivery jobs, HTML/text templates, and integration tests.

Ready infrastructure:

- Action Mailer exists: `app/mailers/application_mailer.rb`, `app/mailers/user_mailer.rb:1`, `app/mailers/passwords_mailer.rb`.
- Solid Queue is production queue adapter: `config/environments/production.rb:47-48`.
- Email verification job pattern exists: `app/jobs/send_email_verification_job.rb:1`.
- Orders, line items, downloads, refunds, and webhooks are already in place.

Missing:

- `app/mailers/order_mailer.rb` does not exist.
- No order mailer templates exist under `app/views/order_mailer/`.
- No `SendOrderConfirmationJob` or `SendRefundReceiptJob` exists.
- SMTP only activates when `SMTP_ADDRESS` is present: `config/environments/production.rb:57-68`.

## Long-Term Roadmap Readiness

| Roadmap Area | Dependency Status |
|---|---|
| Phase 4 Community/Forum | User roles, auth, Action Text, Pagy, Pundit, and Hotwire foundations are ready. Forum models/routes/UI are absent. |
| Phase 5 Admin Chat | Admin roles, Action Cable/Solid Cable, Active Storage, and Hotwire are ready. Chat models/routes/UI are absent. |
| Phase 6 Album Manager | Media, audio player, products, downloads, and checkout dependencies are mostly ready. Album/track/collaborator models are absent. |
| Phase 7 Claude AI Assistant | Admin shell and persistence patterns exist. No Anthropic gem/API code, AI models, or routes found. |
| Phase 8 Plugin System | Commerce foundation exists. Plugin SDK/registry/sandbox models are absent. |
| Phase 9 Design Builder | Design tokens exist in CSS. Theme model/editor/export are absent. |
| Phase 10 SEO | Basic meta description exists through `Seoable`; canonical, OG/Twitter, JSON-LD, sitemap, robots, and validators are absent. |

No meaningful Phase 3.7+ code was found beyond roadmap-oriented comments such as `db/migrate/20260609110001_create_products.rb:9`.
