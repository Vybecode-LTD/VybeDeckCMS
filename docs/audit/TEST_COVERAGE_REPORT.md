---
generated: 2026-06-09
auditor: Codex
suite_result: "PASS: 418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips; PowerShell command exited 1 because Ruby emitted a Fiddle/reline warning on stderr"
---

# Test Coverage Report

Paths are relative to `C:\DEV\VybeDeck\vybedeck_cms`.

## Test File Counts

| Test file | Approx. test count |
|---|---:|
| `test/controllers/passwords_controller_test.rb` | 7 |
| `test/controllers/sessions_controller_test.rb` | 4 |
| `test/integration/admin_access_test.rb` | 4 |
| `test/integration/admin_content_management_test.rb` | 2 |
| `test/integration/admin_embed_test.rb` | 11 |
| `test/integration/admin_media_test.rb` | 15 |
| `test/integration/admin_refunds_test.rb` | 11 |
| `test/integration/admin_revenue_test.rb` | 9 |
| `test/integration/admin_site_settings_test.rb` | 8 |
| `test/integration/audio_player_test.rb` | 10 |
| `test/integration/blog_enhancements_test.rb` | 17 |
| `test/integration/cart_test.rb` | 11 |
| `test/integration/checkout_test.rb` | 13 |
| `test/integration/downloads_test.rb` | 12 |
| `test/integration/member_access_test.rb` | 20 |
| `test/integration/members_and_settings_test.rb` | 21 |
| `test/integration/public_cms_routes_test.rb` | 10 |
| `test/integration/registration_test.rb` | 21 |
| `test/integration/seeds_test.rb` | 1 |
| `test/integration/shop_test.rb` | 12 |
| `test/integration/stripe_webhooks_test.rb` | 8 |
| `test/integration/user_administration_test.rb` | 20 |
| `test/integration/video_player_test.rb` | 12 |
| `test/models/active_storage_variant_test.rb` | 2 |
| `test/models/cart_item_test.rb` | 4 |
| `test/models/cart_test.rb` | 12 |
| `test/models/category_test.rb` | 0 |
| `test/models/embed_parser_test.rb` | 21 |
| `test/models/impersonation_log_test.rb` | 4 |
| `test/models/line_item_test.rb` | 5 |
| `test/models/medium_test.rb` | 15 |
| `test/models/order_test.rb` | 10 |
| `test/models/page_test.rb` | 0 |
| `test/models/post_test.rb` | 6 |
| `test/models/price_test.rb` | 6 |
| `test/models/product_test.rb` | 15 |
| `test/models/site_setting_test.rb` | 13 |
| `test/models/stripe_customer_test.rb` | 4 |
| `test/models/tagging_test.rb` | 0 |
| `test/models/user_profile_test.rb` | 17 |
| `test/models/user_test.rb` | 25 |

## Model Coverage

| Source file | Direct unit test | Coverage status |
|---|---|---:|
| `app/models/application_record.rb` | none | Not directly tested |
| `app/models/cart.rb` | `test/models/cart_test.rb` | ✅ Present |
| `app/models/cart_item.rb` | `test/models/cart_item_test.rb` | ✅ Present |
| `app/models/category.rb` | `test/models/category_test.rb` | 🟡 File exists, 0 tests |
| `app/models/concerns/publishable.rb` | none | 🟡 Integration only through pages/posts |
| `app/models/concerns/seoable.rb` | none | 🟡 Integration only through public meta tests |
| `app/models/current.rb` | none | 🟢 Framework/current-state holder |
| `app/models/embed_parser.rb` | `test/models/embed_parser_test.rb` | ✅ Present |
| `app/models/impersonation_log.rb` | `test/models/impersonation_log_test.rb` | ✅ Present |
| `app/models/line_item.rb` | `test/models/line_item_test.rb` | ✅ Present |
| `app/models/medium.rb` | `test/models/medium_test.rb` | ✅ Present |
| `app/models/order.rb` | `test/models/order_test.rb` | ✅ Present |
| `app/models/page.rb` | `test/models/page_test.rb` | 🟡 File exists, 0 tests |
| `app/models/post.rb` | `test/models/post_test.rb` | ✅ Present |
| `app/models/price.rb` | `test/models/price_test.rb` | ✅ Present |
| `app/models/product.rb` | `test/models/product_test.rb` | ✅ Present |
| `app/models/series.rb` | none | 🟡 Integration only through `blog_enhancements_test` |
| `app/models/session.rb` | none | 🟡 Controller coverage only |
| `app/models/site_setting.rb` | `test/models/site_setting_test.rb` | ✅ Present |
| `app/models/stripe_customer.rb` | `test/models/stripe_customer_test.rb` | ✅ Present |
| `app/models/tagging.rb` | `test/models/tagging_test.rb` | 🟡 File exists, 0 tests |
| `app/models/user.rb` | `test/models/user_test.rb`, `test/models/user_profile_test.rb` | ✅ Present |

## Controller Coverage

| Controller | Integration/controller tests | Coverage status |
|---|---|---:|
| `app/controllers/admin/application_controller.rb` | `admin_access_test`, many admin tests | ✅ Present |
| `app/controllers/admin/categories_controller.rb` | `admin_content_management_test` partially | 🟡 Partial |
| `app/controllers/admin/embeds_controller.rb` | `admin_embed_test` | ✅ Present |
| `app/controllers/admin/impersonations_controller.rb` | `user_administration_test` | ✅ Present |
| `app/controllers/admin/media_controller.rb` | `admin_media_test`, audio/video tests | ✅ Present |
| `app/controllers/admin/orders_controller.rb` | `admin_refunds_test` | ✅ Present for refund/show; inherited index partial |
| `app/controllers/admin/pages_controller.rb` | `admin_content_management_test` | 🟡 Partial |
| `app/controllers/admin/posts_controller.rb` | `admin_content_management_test` | 🟡 Partial |
| `app/controllers/admin/products_controller.rb` | `shop_test` covers public/admin draft show, no admin CRUD test found | 🟡 Partial |
| `app/controllers/admin/revenue_controller.rb` | `admin_revenue_test` | ✅ Present |
| `app/controllers/admin/site_settings_controller.rb` | `admin_site_settings_test` | ✅ Present |
| `app/controllers/admin/users_controller.rb` | `user_administration_test` | ✅ Present for custom actions; index/show partial |
| `app/controllers/application_controller.rb` | broad integration coverage | 🟡 Indirect |
| `app/controllers/carts_controller.rb` | `cart_test` | ✅ Present |
| `app/controllers/categories_controller.rb` | `public_cms_routes_test` | ✅ Present |
| `app/controllers/checkouts_controller.rb` | `checkout_test` | ✅ Present |
| `app/controllers/downloads_controller.rb` | `downloads_test` | ✅ Present |
| `app/controllers/feed_controller.rb` | `blog_enhancements_test` | ✅ Present |
| `app/controllers/members_controller.rb` | `members_and_settings_test` | ✅ Present |
| `app/controllers/pages_controller.rb` | `public_cms_routes_test` | ✅ Present |
| `app/controllers/passwords_controller.rb` | `passwords_controller_test` | ✅ Present |
| `app/controllers/posts_controller.rb` | `public_cms_routes_test`, `blog_enhancements_test`, `member_access_test` | ✅ Present |
| `app/controllers/registrations_controller.rb` | `registration_test` | ✅ Present |
| `app/controllers/series_controller.rb` | `blog_enhancements_test` | ✅ Present |
| `app/controllers/sessions_controller.rb` | `sessions_controller_test`, registration/member/user admin tests | ✅ Present |
| `app/controllers/settings_controller.rb` | `members_and_settings_test`, `member_access_test` | ✅ Present |
| `app/controllers/shop_controller.rb` | `shop_test` | ✅ Present |
| `app/controllers/stripe_webhooks_controller.rb` | `stripe_webhooks_test` | ✅ Present |
| `app/controllers/admin/series_controller.rb` | none | 🔴 Missing source for routed admin series |

## Mailer Coverage

| Mailer | Mailer test | Coverage status |
|---|---|---:|
| `app/mailers/application_mailer.rb` | none | 🟢 Base class |
| `app/mailers/passwords_mailer.rb` | none | 🟡 Indirect via `passwords_controller_test` enqueue assertion |
| `app/mailers/user_mailer.rb` | none | 🟡 Indirect via registration flow/job assertions |
| `app/mailers/order_mailer.rb` | none | Missing, Phase 3.7 not started |

## Job Coverage

| Job | Job test | Coverage status |
|---|---|---:|
| `app/jobs/application_job.rb` | none | 🟢 Base class |
| `app/jobs/send_email_verification_job.rb` | none | 🟡 Indirect via registration tests, no direct job test |
| `SendOrderConfirmationJob` | none | Missing, Phase 3.7 |
| `SendRefundReceiptJob` | none | Missing, Phase 3.7 |

## Policies And Fields

Policies are mostly exercised through integration tests rather than direct policy tests. Explicit policy assertions exist for `PostPolicy#create?` in `test/integration/member_access_test.rb:150-161`. Integration tests exercise `AdminPolicy`, `UserPolicy`, `ProductPolicy`, `DownloadPolicy`, `OrderPolicy#refund?`, `RevenuePolicy`, `SettingPolicy`, `PagePolicy`, and `PostPolicy` through controller behavior.

Custom fields:

- `app/fields/active_storage_field.rb` has integration coverage through admin page/post/media flows, but no direct field test.
- `app/fields/active_storage_multi_field.rb` is behaviorally exercised by downloads/product dashboard paths, but no direct field test exists for `permitted_attribute`.

## Completely Untested Or Weakly Tested Files

Likely no meaningful direct coverage:

- `app/models/application_record.rb`
- `app/models/current.rb`
- `app/models/category.rb` (test file exists but has 0 tests)
- `app/models/page.rb` (test file exists but has 0 tests)
- `app/models/tagging.rb` (test file exists but has 0 tests)
- `app/models/concerns/publishable.rb` (integration only)
- `app/models/concerns/seoable.rb` (integration only)
- `app/models/series.rb` (integration only)
- `app/models/session.rb` (controller integration only)
- `app/mailers/passwords_mailer.rb` (enqueue coverage only)
- `app/mailers/user_mailer.rb` (flow/job coverage only)
- `app/jobs/send_email_verification_job.rb` (flow coverage only)
- `app/fields/active_storage_field.rb`
- `app/fields/active_storage_multi_field.rb`
- `app/controllers/admin/series_controller.rb` is missing despite route.

## Recommended New Tests

1. `test/integration/admin_authorization_test.rb` - verify editors cannot destroy pages, products, media, or series when policies say admin-only.
2. `test/integration/admin_series_test.rb` - verify `/admin/series` index/create/update/destroy behavior after adding the missing controller.
3. `test/models/page_test.rb` - title validation, hierarchy, publishable scope, hero variant declaration.
4. `test/models/category_test.rb` - name/slug behavior and post association.
5. `test/models/tagging_test.rb` - uniqueness/association behavior for post/category links.
6. `test/mailers/user_mailer_test.rb` - email verification subject, recipient, URL token, from address.
7. `test/mailers/passwords_mailer_test.rb` - reset subject, recipient, token URL.
8. `test/jobs/send_email_verification_job_test.rb` - skips missing/verified users and delivers for unverified users.
9. `test/fields/active_storage_multi_field_test.rb` - confirms `permitted_attribute` returns `{ attr => [] }`.
10. Phase 3.7 tests: `test/mailers/order_mailer_test.rb`, `test/jobs/send_order_confirmation_job_test.rb`, and refund/checkout/webhook enqueue assertions.
