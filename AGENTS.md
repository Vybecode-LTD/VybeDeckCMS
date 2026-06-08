# AGENTS.md - VybeDeck CMS

> Project context for Codex and AGENTS.md-compatible agents. New sessions read this first. Keep "Last Completed Task" current at the end of every work session.

## Last Completed Task
Public Hotwire site baseline complete on branch `codex/public-hotwire-site`: page, blog, post, and topic templates render through the public content model; VybeDeck CMS naming and VybeCod.ing styling are applied; seed content is idempotent and media-backed; Active Storage named variants enqueue background transform jobs. Next: review/commit this branch, then start deployment hardening.

## Overview
VybeDeck CMS is a Rails 8 content management system with its own PostgreSQL database, own authentication, public site, and editorial admin. It is an island app and must not share tables or authorization rules with another app.

## Architecture
- Rails 8 monolith.
- PostgreSQL primary database.
- Solid Queue, Solid Cache, and Solid Cable use their own Rails 8 databases/migration paths.
- No Redis.
- Server-rendered Hotwire public site. No React frontend.
- Administrate admin.
- Rails 8 generated authentication.
- Pundit authorization with `User.role`: `author`, `editor`, `admin`.
- Kamal 2 deployment target.

## Content Rules
- Pages and posts are separate models and tables. Never merge them with STI or a `type` column.
- Shared publishing/SEO behavior belongs in concerns.
- Slugs use FriendlyId.
- Active Storage variants must be preprocessed/backgrounded. Do not call `.processed` in request views.
- Public views use the VybeCod.ing design system: `#0a0a0a`, `#e8440a`, JetBrains Mono, OKLCH tokens.

## Build, Test, Run
Use this PATH prefix in PowerShell first:

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
```

Then:

```powershell
ruby bin\rails test
ruby bin\rails db:seed
ruby bin\rails server
```

## Current Branch State
- Branch: `codex/public-hotwire-site`.
- Based on `main` at `f51fd8e`.
- Remote: `https://github.com/Vybecode-LTD/VybeDeckCMS.git`.
- Public site work is implemented and verified but not committed, merged, or pushed.
- See `CLAUDE.md`, `HANDOFF.md`, and `ROADMAP.md` for full details.

## Gotchas
- Switch to `structure.sql` as soon as custom PostgreSQL features are added.
- Do not fold Solid trio migrations into `db/migrate`.
- Production Active Storage local files need a mounted persistent volume and backups.
- Production image variants need libvips or ImageMagick available.
- If this app ever stops being a database island, read the `rails-supabase-rls-bridge` skill before connecting anything.
