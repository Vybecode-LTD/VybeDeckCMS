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
| Last commit | `9ef92be` |

## Last Completed Task (2026-06-08)

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

Phase 2.2 complete. Moving to Phase 2.3 — User Roles Expansion. See `ROADMAP.md`.

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

- `Page` — standalone/hierarchical. Action Text body, Active Storage hero_image, Publishable, Seoable, FriendlyId slug, show_in_nav, position
- `Post` — dated editorial. Action Text body, Active Storage cover_image + gallery, author, categories, Publishable, Seoable, FriendlyId slug history
- `Category` — FriendlyId taxonomy for posts
- `User` — roles: `author` (0), `editor` (1), `admin` (2)
- Concerns: `Publishable` (status enum, live scope), `Seoable` (meta fields — **not yet wired to view output**)

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
220 runs, 592 assertions, 0 failures, 0 errors, 0 skips
```

Key test files:
- `test/integration/public_cms_routes_test.rb`
- `test/integration/admin_access_test.rb`
- `test/integration/admin_content_management_test.rb`
- `test/integration/seeds_test.rb`
- `test/models/active_storage_variant_test.rb`
- `test/integration/registration_test.rb`
- `test/models/site_setting_test.rb`

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

All pre-Phase-1 gaps closed. Remaining items before content is fully production-safe:

1. **S3 not yet active** — code is ready; add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` as Railway env vars to switch Active Storage from local disk to S3.
2. **SMTP not yet active** — code is ready; add `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` (and optionally `SMTP_PORT`, `ACTION_MAILER_FROM`) as Railway env vars to enable password-reset email.
3. `Seoable` concern body is still empty — fields are DB columns, wired to views, but no model-level validation or helpers live in the concern yet.

## Session Protocol

**Start:** Read this file → read `HANDOFF.md` → run `ruby bin\rails test` → confirm green.  
**During:** After each significant change: run affected tests. Bug fix = write failing test first.  
**End:** Update this file (Last Completed / Active Task) + `HANDOFF.md` + commit docs.  
**Commits:** `type(scope): message` format. Stage specific files. Never `git add -A` blindly. Never commit `storage/`, `tmp/`, `log/`, or any credential file.
