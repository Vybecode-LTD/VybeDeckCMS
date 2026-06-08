# CLAUDE.md - VybeDeck CMS Handoff

> New Claude/Codex sessions should read this first. Keep "Last Completed Task" current at the end of every work session.

## Project Snapshot
- Project name: VybeDeck CMS.
- Repo path: `C:\DEV\VybeDeck\vybedeck_cms`.
- GitHub remote: `https://github.com/Vybecode-LTD/VybeDeckCMS.git`.
- Current branch: `codex/public-hotwire-site`.
- Main branch status at branch point: `f51fd8e` (`Merge Session 2 admin panel baseline`).
- Current branch state: public site work is implemented and tested, but not committed, merged, or pushed.
- Runtime: Rails 8.1, Ruby 3.4, PostgreSQL, Hotwire, Minitest.

## Last Completed Task
Public Hotwire site baseline complete on branch `codex/public-hotwire-site`: page, blog, post, and topic templates render through the public content model; VybeDeck CMS naming and VybeCod.ing styling are applied; seed content is idempotent and media-backed; Active Storage named variants enqueue background transform jobs.

Verification from June 8, 2026:
- `ruby bin\rails test` passed: `29 runs, 141 assertions, 0 failures, 0 errors, 0 skips`.
- `ruby bin\rails db:seed` completed.
- HTTP smoke checks passed for `/`, `/blog`, `/topics/announcements`, and compiled CSS.

## Completed Task History
1. Agent kit assembled with root `AGENTS.md`, root `CLAUDE.md`, and six project-scoped skills under `.codex/skills/` and `.claude/skills/`.
2. Rails 8 CMS foundation generated in `vybedeck_cms` with PostgreSQL and the Rails 8 Solid trio defaults.
3. Core CMS model baseline added: separate `Page` and `Post` models, `Category`, `Tagging`, FriendlyId slugs, Action Text bodies, Active Storage media, `Publishable` and `Seoable` concerns, generated Rails authentication, Pundit roles, and public route policy coverage.
4. Session 2 admin baseline merged to `main` and pushed: Administrate installed, dashboards trimmed to Page/Post/Category/User, admin namespace gated to editor/admin via Pundit, and admin access/create tests passing.
5. Public Hotwire site baseline implemented on `codex/public-hotwire-site`: public templates, shared header/footer, VybeCod.ing CSS, idempotent seeds with generated media, and async Active Storage variant enqueue tests.

## Architecture
- Rails 8 monolith and database island. Do not share this database with another app.
- PostgreSQL primary database.
- Solid Queue, Solid Cache, and Solid Cable use their own database configs/migration paths per Rails 8 defaults.
- No Redis.
- Public site is server-rendered Hotwire. There is no React frontend.
- Admin is Administrate. Own the Administrate views when polishing admin UX.
- Auth is Rails 8 generated authentication.
- Authorization is Ruby/Pundit using `User.role`: `author`, `editor`, `admin`.
- Content model rule: `Page` and `Post` are separate tables/models. Never combine them with STI or a `type` column.

## Current Content Model
- `Page`: standalone/hierarchical/nav-placed content with `parent`, `children`, Action Text `body`, `hero_image`, SEO fields, status, slug, nav position, and `show_in_nav`.
- `Post`: dated editorial content with `author`, `categories`, Action Text `body`, `cover_image`, `gallery`, excerpt, SEO fields, status, slug history.
- `Category`: FriendlyId topic taxonomy for posts.
- Shared concerns: `Publishable` for status/live scope and `Seoable` for metadata.

## Public Site Implementation
- Layout and naming: `app/views/layouts/application.html.erb` now uses "VybeDeck CMS", Turbo morph refresh, shared public header/footer.
- Public helpers: `app/helpers/application_helper.rb` provides nav pages, page titles, status labels, and readable dates.
- Public controllers now render templates instead of plain text:
  - `PagesController#show`
  - `PostsController#index`
  - `PostsController#show`
  - `CategoriesController#show`
- Views added:
  - `app/views/shared/_site_header.html.erb`
  - `app/views/shared/_site_footer.html.erb`
  - `app/views/pages/show.html.erb`
  - `app/views/posts/index.html.erb`
  - `app/views/posts/show.html.erb`
  - `app/views/posts/_post_card.html.erb`
  - `app/views/categories/show.html.erb`
- Styling: `app/assets/stylesheets/application.css` uses the VybeCod.ing design system: `#0a0a0a`, `#e8440a`, JetBrains Mono, OKLCH tokens, restrained public CMS layout.

## Media And Jobs
- `Page#hero_image` defines a preprocessed `:hero` variant.
- `Post#cover_image` defines a preprocessed `:cover` variant.
- `Post#gallery` defines a preprocessed `:thumb` variant.
- Views render original attachments, not `.processed` variants, so requests do not do inline image transformation.
- Local ImageMagick/Vips binaries were not present during implementation. Tests verify enqueue behavior, not actual image transformation execution.

## Seeds
- `db/seeds.rb` is idempotent.
- Creates admin user: `admin@vybedeck.test` with password `password`.
- Creates categories: `Announcements`, `Field Notes`.
- Creates pages: `home`, `about`.
- Creates posts: `launch-notes`, `editorial-workflow`, and draft `private-draft`.
- Generates small PNG attachments in Ruby and attaches them once.

## Tests
- Current full suite: `29 runs, 141 assertions`.
- Important files:
  - `test/integration/public_cms_routes_test.rb`
  - `test/integration/admin_access_test.rb`
  - `test/integration/admin_content_management_test.rb`
  - `test/integration/seeds_test.rb`
  - `test/models/active_storage_variant_test.rb`
- Use Minitest unless there is a strong reason to change.

## Windows Command Prefix
Use this PATH prefix before Rails commands in PowerShell:

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
```

Then run Rails through Ruby:

```powershell
ruby bin\rails test
ruby bin\rails db:seed
ruby bin\rails server
```

## Git State For Next Agent
- The branch `codex/public-hotwire-site` contains uncommitted application changes.
- Root workspace docs under `C:\DEV\VybeDeck` are outside the app Git repo.
- Repo-local docs added in this handoff should be committed with the branch.
- Do not merge or push until the user asks.
- Before commit, inspect staged files and secrets. Do not use `git add .` blindly.

## Known Gaps
- Browser visual validation was attempted, but the in-app browser JS execution entry point was not exposed in the active tool list. Fallback HTTP/rendered-content checks were used.
- Production image processing needs a real processor binary in the image/runtime: libvips or ImageMagick.
- Deployment has not been hardened yet.
- Admin UX is functional but not yet polished.
- Public SEO artifacts such as sitemap/robots/canonical helpers are not implemented yet.
- No production content import has been performed.

## Next Step
Review and commit `codex/public-hotwire-site`, then move into deployment hardening:
- Kamal config and secrets.
- Solid Queue runtime posture.
- Active Storage persistence and backups.
- Production image processor.
- Production environment settings and smoke checklist.
