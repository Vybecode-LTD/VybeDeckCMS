# VybeDeck CMS Roadmap

Updated: 2026-06-08

## Current Status
VybeDeck CMS has a Rails 8 foundation, authentication, Pundit roles, separate Page/Post models, Administrate admin, public Hotwire templates, VybeCod.ing public styling, idempotent seed content, and background-enqueued Active Storage variants.

The current branch is `codex/public-hotwire-site`. The public site work is verified but not committed, merged, or pushed.

## Phase 0 - Commit Current Public Site Branch
- Review the diff for `codex/public-hotwire-site`.
- Stage only intended app/docs files.
- Run `ruby bin\rails test`.
- Commit with a focused message such as `feat(public): add Hotwire CMS site baseline`.
- Merge back to `main` and push only after user approval.

## Phase 1 - Deployment Hardening
- Audit `config/deploy.yml` for the real host, image name, registry, proxy, SSL, and app secrets.
- Confirm `RAILS_MASTER_KEY`, database credentials, and Kamal secrets workflow.
- Decide whether Solid Queue runs in Puma via `SOLID_QUEUE_IN_PUMA` for the one-container deployment or as `bin/jobs`.
- Verify production database names for primary/cache/queue/cable.
- Confirm health check behavior at `/up`.
- Add a deployment smoke checklist.

## Phase 2 - Media And Background Processing
- Add libvips or ImageMagick to the production image/runtime.
- Verify Active Storage variants can actually transform outside tests.
- Confirm local Active Storage is mounted at `/rails/storage`.
- Define backup/restore expectations for uploaded media.
- Consider S3-compatible storage if local volume backup becomes operationally weak.

## Phase 3 - Editorial Admin UX
- Own Administrate views for Page/Post editing.
- Add better publish controls and draft/published affordances.
- Add image alt/caption fields or editorial guidance for media.
- Add preview links for drafts.
- Improve category assignment ergonomics.

## Phase 4 - Public Site Polish
- Add sitemap and robots endpoints.
- Add canonical/meta helpers from `Seoable`.
- Add RSS/Atom for posts if desired.
- Add empty states for topic/blog lists.
- Add system tests or browser screenshot checks for desktop/mobile layouts.
- Audit accessibility: headings, landmarks, contrast, focus states, image alt strategy.

## Phase 5 - Content Import
- Use the `content-migration-importer` skill for WordPress, markdown, or structured imports.
- Keep imports idempotent and reversible.
- Map durable pages to `Page` and dated/articles to `Post`.
- Preserve slugs and redirects where needed.

## Phase 6 - Search And Discovery
- Add basic public search only after the public content surface stabilizes.
- If using PostgreSQL full text search, switch schema format to `:sql` before adding custom indexes/functions.
- Keep search in Rails/Postgres unless requirements justify an external service.

## Phase 7 - Production Readiness Review
- Run security scan/review.
- Run dependency audit.
- Confirm admin authorization coverage.
- Confirm no credentials or generated local storage are committed.
- Confirm restore path for database and uploaded media.
