---
generated: 2026-06-09
auditor: Codex
suite_result: "PASS: 418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips; PowerShell command exited 1 because Ruby emitted a Fiddle/reline warning on stderr"
---

# VybeDeck CMS Audit Summary

Paths in this report are relative to `C:\DEV\VybeDeck\vybedeck_cms`.

## Project Description

VybeDeck CMS is a Rails 8.1, PostgreSQL-backed publishing and commerce monolith for music labels, independent artists, and creative agencies. It provides a public Hotwire site, an Administrate editorial back office, Rails-generated authentication, Pundit authorization, media management, membership roles, Stripe checkout, digital downloads, refunds, and revenue reporting.

## Overall Assessment

**SIGNIFICANT GAPS.** The codebase is broadly on track: Phases 1.1 through 3.6 are mostly implemented, the full suite matches the documented baseline, and the production deployment files are more complete than the documentation suggests. The remaining gaps are important before production traffic: admin authorization integration is incomplete for custom/admin CRUD surfaces, S3 and SMTP depend on external Railway environment activation, and the admin Series route points to a missing controller.

## Test Suite Result

✅ PASS: `418 runs, 1040 assertions, 0 failures, 0 errors, 0 skips`.

The count matches the documented baseline in `CLAUDE.md` and `HANDOFF.md`.

PowerShell returned exit code 1 because Ruby emitted this warning after the green test result: `reline-0.6.3/lib/reline/io/windows.rb:1: warning: ... fiddle/import.rb is found in fiddle, which will no longer be part of the default gems starting from Ruby 4.0.0.`

## Top Risks

1. 🟠 HIGH - Admin authorization is not fully wired for custom admin actions and Administrate CRUD integration. `Admin::ApplicationController` includes `Pundit::Authorization` and gates `/admin` through `AdminPolicy`, but it does not include `Administrate::Punditize`; several custom actions also omit explicit `authorize` calls. Evidence: `app/controllers/admin/application_controller.rb:10`, `app/controllers/admin/application_controller.rb:38`, local gem `administrate-1.0.0/app/controllers/administrate/application_controller.rb:254-255`, `app/controllers/admin/media_controller.rb:40`, `app/controllers/admin/site_settings_controller.rb:3`.
2. 🟠 HIGH - Durable production files and production mail are not active until Railway env vars are set. S3 is configured but conditional on `AWS_BUCKET`; SMTP is conditional on `SMTP_ADDRESS`. Evidence: `config/environments/production.rb:25`, `config/storage.yml:11-16`, `config/environments/production.rb:57-68`.
3. 🟡 MEDIUM - Admin Series management is routed but missing its controller. Evidence: `config/routes.rb:27`, `app/dashboards/series_dashboard.rb:3`; `app/controllers/admin/series_controller.rb` is missing.

## Top Strengths

1. ✅ Strong test baseline: 418 tests pass, matching the documented 418/1040 baseline exactly.
2. ✅ Architecture choices are mostly respected: separate Page/Post tables, Rails auth, Minitest, Propshaft, Solid Queue/Cache/Cable, no React, no Redis, Stripe-only payments.
3. ✅ Production deployment is more ready than the stale docs imply: Dockerfile already installs `libvips`, sets `RAILS_ENV=production`, and precompiles assets. Evidence: `Dockerfile:19`, `Dockerfile:24`, `Dockerfile:61`.

## Phase Summary

| Phase | Rating | Notes |
|---|---:|---|
| 1.1 Media Manager | Complete with Issue Found | Model/controller/policy/tests exist; custom controller does not enforce `MediumPolicy#destroy?`. |
| 1.2 Audio Player | Complete | Stimulus controller, shared partial, admin media integration tests present. |
| 1.3 Video Player | Complete | Stimulus controller, shared partial, fullscreen controls, tests present. |
| 1.4 Embed Widgets | Complete with Issue Found | Parser, preview route, picker, CSP, tests present; preview action lacks explicit resource authorize beyond admin gate. |
| 1.5 Blog Enhancements | Partial | Reading time, feed, public series pages exist; admin series controller is missing. |
| 2.1 User Profile | Complete | User profile fields, MembersController, SettingsController, policies/tests present. |
| 2.2 Registration | Complete | Registration, verification mailer/job, SiteSetting, tests present. |
| 2.3 Roles Expansion | Complete | `member` and `subscriber` roles, gated posts, policies/tests present. |
| 2.4 User Administration | Complete with Issue Found | Ban/unban/impersonation/bulk role exist; index/show have only broad admin gate. |
| 3.1 Stripe Foundation | Complete | Models, policies, dashboards, webhook controller/tests present. |
| 3.2 Public Shop | Complete | Routes/controller/views/tests present. |
| 3.3 Shopping Cart | Complete with Issue Found | Cart works and is tested; `show/update/remove` do not explicitly authorize cart resources. |
| 3.4 Checkout | Complete with Issue Found | Checkout works and is tested; `create` intentionally has no Pundit authorization/skip marker. |
| 3.5 Digital Downloads | Complete | Download files, controller, policy, field, tests present. |
| 3.6 Refunds & Revenue | Complete | Refund and revenue controllers/views/policies/tests present. |

## Priority Actions

1. Fix admin authorization: include/configure Administrate Pundit integration and add explicit `authorize` or `skip_authorization` decisions for custom admin/public actions.
2. Add `app/controllers/admin/series_controller.rb` or remove/adjust `config/routes.rb:27`; add admin Series route tests.
3. Activate S3 in Railway before uploading production downloads: set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, and `AWS_BUCKET`.
4. Activate SMTP in Railway and then implement Phase 3.7 `OrderMailer` plus jobs/templates/tests.
5. Fill direct test gaps for mailers/jobs, empty model tests, custom fields, and authorization edge cases.
