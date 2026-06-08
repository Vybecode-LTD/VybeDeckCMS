# VybeDeck CMS

Rails 8 content management system for VybeDeck CMS.

VybeDeck CMS is a database-island Rails monolith with:

- Public Hotwire site.
- Administrate editorial admin.
- Rails generated authentication.
- Pundit roles: `author`, `editor`, `admin`.
- Separate `Page` and `Post` models.
- Action Text bodies and Active Storage media.
- FriendlyId slugs.
- PostgreSQL plus the Rails 8 Solid trio.

## Setup

```sh
bin/setup
bin/rails db:create db:migrate
bin/rails test
```

On this Windows workspace, run Rails through Ruby after prefixing the local toolchain path:

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
ruby bin\rails test
ruby bin\rails db:seed
ruby bin\rails server
```

## Current Status

The current handoff branch is `codex/public-hotwire-site`. Public page/blog/post/topic views, VybeCod.ing styling, idempotent seed content, and background-enqueued Active Storage variants are implemented and tested.

See:

- `CLAUDE.md` for full agent handoff context.
- `HANDOFF.md` for immediate takeover steps.
- `ROADMAP.md` for upcoming work.
