# VybeDeck CMS — Session Handoff

> New agents read this file first, then `ROADMAP.md`.
> Keep "Last Completed" current at the end of every session.

**Updated:** 2026-06-08  
**Branch:** `main`  
**Last commit:** gaps-close session (uncommitted) — all seven pre-Phase-1 gaps resolved; tests 33/148 green

---

## Where Things Are

| Item | Value |
|------|-------|
| Workspace | `C:\DEV\VybeDeck` |
| Rails app | `C:\DEV\VybeDeck\vybedeck_cms` |
| GitHub | `https://github.com/Vybecode-LTD/VybeDeckCMS.git` |
| Deployed | Railway (auto-deploy from `main`) |
| Branch | `main` — everything is merged and pushed |
| Tests | `33 runs, 148 assertions, 0 failures, 0 errors, 0 skips` |

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

## What Is Built

### Foundation
- Rails 8.1 monolith — PostgreSQL primary; Solid Queue/Cache/Cable share the same PG connection in production (required by Railway single-Postgres constraint)
- Propshaft asset pipeline; Importmap for JS
- No Redis; no Webpack; no Node build step

### Auth & Roles
- Rails 8 generated authentication — `SessionsController`, `PasswordsController`
- `User` model with `role` enum: `author` (0), `editor` (1), `admin` (2)
- Pundit policies on all admin and public controllers

### Content
- `Page` — standalone/hierarchical. Has `parent`, `children`, Action Text `body`, `hero_image` (Active Storage), SEO fields, `status`, FriendlyId slug, `show_in_nav`, `position`
- `Post` — dated editorial. Has `author`, `categories`, Action Text `body`, `cover_image` + `gallery` (Active Storage), `excerpt`, SEO fields, `status`, FriendlyId slug history
- `Category` — FriendlyId taxonomy for posts
- Concerns: `Publishable` (status enum, `live` scope, `published_at` auto-set), `Seoable` (meta fields present but not yet wired to view output)

### Admin Panel
- Administrate 1.0, namespace `admin/`
- Dashboards: `PageDashboard`, `PostDashboard`, `CategoryDashboard`, `UserDashboard`
- Custom `ActiveStorageField` (own implementation — Administrate 1.0 has no built-in)
- `app/views/admin/application/_form.html.erb` overrides default form with `multipart: true`
- View-on-site / Preview-draft buttons on Page and Post show pages
- Collection filters: draft / published / archived on Page and Post

### Public Site
- `PagesController#show` routes `/` → `home` slug and `/:id` → any slug
- `PostsController#index` at `/blog`, `#show` at `/blog/:id`
- `CategoriesController#show` at `/topics/:id`
- Shared partials: `_site_header.html.erb`, `_site_footer.html.erb`
- `ApplicationHelper`: `public_nav_pages`, `page_title`, `status_label`, `readable_date`

### Content Quality & UX Fixes
- `User#display_name` column + `User#byline` helper (falls back to `email_address`)
- `<meta name="description">` emitted from layout via `content_for(:description)`; set on all public show/index views
- Empty states on blog index and category show pages
- Pagy pagination (12/page, nav renders only when pages > 1) on `PostsController#index` and `CategoriesController#show`
- SMTP config in `production.rb` reads `SMTP_*` Railway env vars — silent until added
- `aws-sdk-s3` gem added; `storage.yml` has amazon service; production auto-switches to S3 when `AWS_BUCKET` set

### Design System
- **Font:** Inter (variable, Google Fonts `@import` in CSS)
- **Light theme:** `--bg #f8f7f5`, white cards, `--text #18150e`, accent `#e8440a`
- **Dark theme:** `--bg #0f0e0d`, `#1a1816` cards, `--text #f0ece4`, same accent
- **Switching:** `@media (prefers-color-scheme: dark)` for system pref; `[data-color-scheme="dark"]` attribute for manual; no-flash `localStorage` read in `<head>`
- **Auth layout** (`layouts/auth.html.erb`): centred card, brand at top, no nav/footer
- **Theme toggle** in site header: sun/moon SVG, persists to `localStorage`

### Deployment
- **Platform:** Railway (PaaS — not Kamal/VPS)
- **`railway.toml`:** `PORT=80`, `healthcheckTimeout=600`, `restartPolicyType=on_failure`
- **`bin/docker-entrypoint`:** runs `db:migrate` with 12-retry loop before server start; no seeds on boot
- **`config/database.yml`:** all four DB configs (`primary`, `cache`, `queue`, `cable`) point to `DATABASE_URL`
- **Secrets:** `RAILS_MASTER_KEY` set as Railway env var — never committed

---

## Seeds

Admin user created by `db/seeds.rb` (idempotent):

| Field | Value |
|-------|-------|
| Email | `admin@vybedeck.test` |
| Password | `password` |
| Role | `admin` |

Categories: `Announcements`, `Field Notes`  
Pages: `home`, `about`  
Posts: `launch-notes` (published), `editorial-workflow` (published), `private-draft` (draft)

---

## Known Issues & Gaps

| Issue | Severity | Notes |
|-------|----------|-------|
| S3 not yet active | Medium | `aws-sdk-s3` gem added, `storage.yml` and production config ready. Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` Railway env vars to activate. |
| SMTP not yet active | Low | Config ready in `production.rb`. Add `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` Railway env vars to activate password-reset email. |
| No `alt_text` field on media | Low | All `image_tag` calls use `alt: ""` — will be addressed in Phase 1 Media Manager |
| SEO deferred | Intentional | Owner requested: complete features first, then Phase 10 SEO |

---

## Immediate Next Session Checklist

Run this before starting new work:

```powershell
# 1. Set PATH
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms

# 2. Confirm green baseline
ruby bin\rails test

# 3. Start work on Phase 1 — Media Manager
```

**Next recommended phase:** Phase 1 — Media Manager (see `ROADMAP.md`)

Suggested start order inside Phase 1:
1. `Medium` model + admin media library grid (Pagy already wired)
2. Drag-and-drop Stimulus upload controller
3. Inline "pick from library" modal on Page/Post forms
4. Add AWS env vars to Railway → S3 becomes live (code already deployed)

---

## Architecture Rules (never break these)

- `Page` and `Post` are **separate models, separate tables**. No STI. No `type` column.
- Authorization lives **only in Pundit policies** — no `before_action :authorize` shortcuts that skip policies.
- Database is a **Rails island** — no other app shares this PostgreSQL instance.
- **No secrets in the repo.** `RAILS_MASTER_KEY` and all API keys are Railway env vars.
- **One release creator.** CI (Railway) builds and deploys. Never `git push --force` to main.
- Commits use **conventional format:** `type(scope): message` — `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

---

## File Map (things that are unusual or easy to forget)

```
app/fields/active_storage_field.rb          Custom Administrate field (no built-in in v1.0)
app/views/fields/active_storage/            _form and _show partials for above
app/views/admin/application/_form.html.erb  Overrides default form to add multipart:true
app/views/admin/pages/show.html.erb         cms_page alias avoids clash with Administrate presenter
app/views/layouts/auth.html.erb             Separate auth layout (no nav, centred card)
app/assets/stylesheets/application.css      All design tokens, light+dark themes, components
bin/docker-entrypoint                       Retry loop for db:migrate before server starts
railway.toml                                PORT=80 is CRITICAL — do not remove
config/database.yml (production)            All 4 DB configs share DATABASE_URL
```

---

## Commit History (this session)

| Hash | Message |
|------|---------|
| `9ef92be` | feat(design): complete light/dark design system with Inter font and auth layout |
| `34be6b6` | feat(admin): Phase 3 admin UX polish |
| `7306d7c` | fix(deploy): pin PORT=80 for Thruster in railway.toml |
| `8cb8289` | fix(deploy): retry db:migrate on boot, 600s healthcheck, fix vendor copy |
| `4670757` | fix(deploy): increase healthcheck timeout to 300s for large image |
| `b5a56e4` | fix(deploy): use db:migrate in entrypoint instead of db:prepare |
| `4b054e5` | feat(deploy): configure Railway deployment |
