---
generated: 2026-06-09
auditor: Codex
suite_result: "PASS: 418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips; PowerShell command exited 1 because Ruby emitted a Fiddle/reline warning on stderr"
---

# Remediation Plan

Paths are relative to `C:\DEV\VybeDeck\vybedeck_cms`.

## Tier 1 - Before Any Production Traffic

| Priority | Severity | Fix | Files | Scope |
|---:|---:|---|---|---|
| 1 | 🟠 HIGH | Wire Administrate CRUD to Pundit policies. Include `Administrate::Punditize` in the admin base controller or override `authorized_action?`, `authorize_resource`, and `scoped_resource` equivalently. Add tests that editors cannot perform admin-only destroys/refunds/settings operations. | `app/controllers/admin/application_controller.rb`, admin controller tests | Medium |
| 2 | 🟠 HIGH | Add explicit `authorize`, `policy_scope`, or documented `skip_authorization` to custom actions. Focus first on `Admin::MediaController#destroy/#bulk_destroy`, `Admin::SiteSettingsController#show/#update`, `CartsController` mutations, and `CheckoutsController#create`. | `app/controllers/admin/media_controller.rb`, `app/controllers/admin/site_settings_controller.rb`, `app/controllers/carts_controller.rb`, `app/controllers/checkouts_controller.rb` | Medium |
| 3 | 🟡 MEDIUM | Fix Admin Series route. Either create `Admin::SeriesController < Admin::ApplicationController` or remove/replace `config/routes.rb:27`; add integration tests for `/admin/series`. | `config/routes.rb`, new `app/controllers/admin/series_controller.rb`, tests | Small |
| 4 | 🟠 HIGH | Activate S3 before production downloads. Set Railway `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET`; verify uploads/downloads survive deploys. | Railway env, `config/storage.yml`, `config/environments/production.rb` | External config |
| 5 | 🟠 HIGH | Activate SMTP before production users depend on email. Set `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`, optional `SMTP_PORT`, `ACTION_MAILER_FROM`, `RAILS_HOST`; verify password reset and verification delivery. | Railway env, `config/environments/production.rb` | External config |
| 6 | 🟡 MEDIUM | Verify local `config/master.key` is never committed or included in Docker builds. It is currently ignored and untracked; keep it that way. | `.gitignore`, `.dockerignore`, local workspace | 1-line/checklist |

## Tier 2 - Phase 3.7 Email Notifications

| Priority | Severity | Fix | Files | Scope |
|---:|---:|---|---|---|
| 1 | 🟠 HIGH | Add `OrderMailer` with `confirmation(order)`, `download_ready(order)`, and `refund_receipt(order)`. | `app/mailers/order_mailer.rb`, `app/views/order_mailer/*` | Medium |
| 2 | 🟠 HIGH | Add async jobs for order confirmation/download-ready and refund receipts using the existing Solid Queue pattern. | `app/jobs/send_order_confirmation_job.rb`, `app/jobs/send_refund_receipt_job.rb` | Small |
| 3 | 🟠 HIGH | Wire confirmation emails from either `StripeWebhooksController#handle_payment_intent_succeeded` or `CheckoutsController#confirmation`; avoid double-send with an idempotency flag or job guard. | `app/controllers/stripe_webhooks_controller.rb`, `app/controllers/checkouts_controller.rb`, possible `orders` migration | Medium |
| 4 | 🟡 MEDIUM | Wire refund receipt after a successful Stripe refund. | `app/controllers/admin/orders_controller.rb` | Small |
| 5 | 🟡 MEDIUM | Add mailer/job/integration tests. | `test/mailers/order_mailer_test.rb`, `test/jobs/*`, `test/integration/checkout_test.rb`, `test/integration/stripe_webhooks_test.rb`, `test/integration/admin_refunds_test.rb` | Medium |

## Tier 3 - Technical Debt

| Priority | Severity | Fix | Files | Scope |
|---:|---:|---|---|---|
| 1 | 🟡 MEDIUM | Replace empty generated model tests with real coverage for `Page`, `Category`, and `Tagging`. | `test/models/page_test.rb`, `test/models/category_test.rb`, `test/models/tagging_test.rb` | Small |
| 2 | 🟡 MEDIUM | Add direct mailer tests for existing mailers. | `test/mailers/passwords_mailer_test.rb`, `test/mailers/user_mailer_test.rb` | Small |
| 3 | 🟡 MEDIUM | Add job test for `SendEmailVerificationJob`. | `test/jobs/send_email_verification_job_test.rb` | Small |
| 4 | 🟡 MEDIUM | Add direct tests for custom Administrate fields. | `test/fields/active_storage_field_test.rb`, `test/fields/active_storage_multi_field_test.rb` | Small |
| 5 | 🟢 LOW | Add explicit `skip_authorization` to intentionally public auth/feed/webhook endpoints if the project wants audit-visible compliance with the "Pundit every action" rule. | `SessionsController`, `PasswordsController`, `RegistrationsController`, `FeedController`, `StripeWebhooksController` | Small |
| 6 | 🟢 LOW | Add SEO validators when Phase 10 starts. | `app/models/concerns/seoable.rb`, model tests | Small |

## Recommended Implementation Order

1. Fix admin Pundit integration and add regression tests for editor/admin destructive permissions.
2. Fix or remove the Admin Series route.
3. Add explicit authorization or skip markers for custom non-Administrate actions.
4. Activate and smoke-test S3 and SMTP in Railway.
5. Implement Phase 3.7 mailers/jobs with idempotent delivery behavior.
6. Fill direct test gaps for mailers, jobs, empty model tests, and custom fields.
