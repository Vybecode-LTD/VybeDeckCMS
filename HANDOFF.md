# VybeDeck CMS Handoff

Updated: 2026-06-08

## Where Things Are
- Workspace: `C:\DEV\VybeDeck`
- Rails repo: `C:\DEV\VybeDeck\vybedeck_cms`
- GitHub remote: `https://github.com/Vybecode-LTD/VybeDeckCMS.git`
- Current branch: `codex/public-hotwire-site`
- Main head at branch point: `f51fd8e` (`Merge Session 2 admin panel baseline`)

## Current Work State
The public Hotwire site baseline has been implemented and verified. It has not been committed, merged, or pushed.

Changed application areas:
- Public controllers now render templates.
- Shared public header/footer added.
- Public page/blog/post/topic templates added.
- VybeCod.ing application CSS added.
- Page/Post image variants configured for background preprocessing.
- Idempotent seed content added with generated PNG attachments.
- Integration/model tests updated and added.
- Repo-local handoff docs added.

## Verification Already Run
Use the Windows PATH prefix from `CLAUDE.md` before these commands.

```powershell
ruby bin\rails test
```

Fresh result from June 8, 2026:

```text
29 runs, 141 assertions, 0 failures, 0 errors, 0 skips
```

Also run successfully:

```powershell
ruby bin\rails db:seed
```

HTTP smoke checks returned `200` and expected content for:
- `/`
- `/blog`
- `/topics/announcements`
- compiled `application.css`

## Immediate Next Actions
1. Review the uncommitted diff on `codex/public-hotwire-site`.
2. Run `ruby bin\rails test`.
3. Commit the public-site branch if the diff is acceptable.
4. Merge to `main` and push only when the user explicitly asks.
5. Start deployment hardening from `ROADMAP.md`.

## Suggested Commit Scope
Commit the current branch as one feature commit unless review finds unrelated changes:

```text
feat(public): add Hotwire CMS site baseline
```

Expected staged scope:
- `AGENTS.md`
- `CLAUDE.md`
- `HANDOFF.md`
- `ROADMAP.md`
- `README.md`
- `app/assets/stylesheets/application.css`
- `app/controllers/categories_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/controllers/posts_controller.rb`
- `app/helpers/application_helper.rb`
- `app/models/page.rb`
- `app/models/post.rb`
- `app/views/**`
- `db/seeds.rb`
- `test/integration/public_cms_routes_test.rb`
- `test/integration/seeds_test.rb`
- `test/models/active_storage_variant_test.rb`

## Do Not Accidentally Commit
- `storage/`
- `tmp/`
- `log/`
- local credentials or environment files
- generated server logs

## Known Issues And Caveats
- In-app browser automation was unavailable because the JS execution entry point was not exposed after tool discovery. The fallback was HTTP/rendered-content validation.
- Active Storage variant tests prove transform jobs enqueue; they do not prove a production image processor is installed.
- Local machine did not have ImageMagick/Vips binaries during implementation.
- Production deployment needs explicit hardening before launch.

## Handoff Summary For A New Agent
You are taking over a Rails 8 CMS called VybeDeck CMS. The app is a database island with separate Page and Post models, Action Text, Active Storage, FriendlyId, Rails auth, Pundit roles, Administrate admin, and a public Hotwire site. The branch `codex/public-hotwire-site` is ready for review/commit. Preserve the separation between pages and posts, keep authorization in Pundit, and do not introduce RLS or a shared database unless the architecture changes deliberately.
