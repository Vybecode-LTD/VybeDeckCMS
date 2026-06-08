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

**Design system rewrite** — complete light/dark theme with Inter variable font, OKLCH design
tokens, glass-morphism header, rounded form controls, auth card layout, no-flash localStorage
theme toggle. Verified via computed-style inspection in both modes. Committed to `main`.

Previous sessions: Rails 8 foundation → auth/Pundit → Page/Post/Category models → Administrate
admin → public Hotwire site → Railway deployment → admin UX polish (Phase 3) → design system.

## Active Task

Phase 1 — Media Manager (not yet started). See `ROADMAP.md` Phase 1.

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
29 runs, 141 assertions, 0 failures, 0 errors, 0 skips
```

Key test files:
- `test/integration/public_cms_routes_test.rb`
- `test/integration/admin_access_test.rb`
- `test/integration/admin_content_management_test.rb`
- `test/integration/seeds_test.rb`
- `test/models/active_storage_variant_test.rb`

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

1. `libvips` not in Dockerfile — Active Storage variants enqueue but don't run in production
2. Active Storage on local volume — needs S3 before content is irreplaceable in Railway
3. `Seoable` not wired to views — `<title>` and `<meta>` don't read model fields yet
4. `display_name` missing on User — post bylines show email addresses publicly
5. No SMTP config — password reset emails silently fail in production
6. No pagination (Pagy) — blog/topic lists will degrade at scale
7. No empty states on blog/topic list pages

## Session Protocol

**Start:** Read this file → read `HANDOFF.md` → run `ruby bin\rails test` → confirm green.  
**During:** After each significant change: run affected tests. Bug fix = write failing test first.  
**End:** Update this file (Last Completed / Active Task) + `HANDOFF.md` + commit docs.  
**Commits:** `type(scope): message` format. Stage specific files. Never `git add -A` blindly. Never commit `storage/`, `tmp/`, `log/`, or any credential file.
