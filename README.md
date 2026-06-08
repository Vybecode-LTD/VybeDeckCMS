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

## Video format support

The video player (`app/views/shared/_video_player.html.erb`) supports **MP4** and **WebM** natively in all modern browsers.

**AVI files are not playable in the browser.** Before uploading an AVI, re-encode it to MP4 with H.264 using FFmpeg:

```sh
ffmpeg -i input.avi -c:v libx264 -crf 23 -preset fast -c:a aac output.mp4
```

For batch conversion:

```sh
for f in *.avi; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 -preset fast -c:a aac "${f%.avi}.mp4"
done
```

After re-encoding, upload the `.mp4` file through the admin Media Library.

## Current Status

Phase 1.3 (Video Player) complete. Public site + admin panel with full media management (images, audio player, video player), editorial content, design system, and Railway deployment.

See:

- `CLAUDE.md` for full agent handoff context.
- `HANDOFF.md` for immediate takeover steps.
- `ROADMAP.md` for upcoming work.
