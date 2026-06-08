# STARTUP.md — VybeDeck CMS Agent Briefing

> **Read this entire file before touching any code.**
> This is the primary orientation document for any new agent session.
> It is more detailed than CLAUDE.md and tells you not just *what* is built
> but *why* decisions were made, what traps to avoid, and exactly what to do next.

---

## 1. What This Project Is

VybeDeck CMS is a **self-hosted, Rails 8 monolith** built for music labels, independent
artists, and creative agencies. It is owned by **Vybecode Ltd** and deployed on **Railway**
(a PaaS platform — not a VPS, not Heroku, not Render).

The product vision is a single back-office that handles:
- Public website publishing (pages + blog posts)
- Media management (audio, video, images, documents)
- E-commerce (album sales, digital downloads, one-off products)
- Community and forum
- Collaborative album production workspace
- Admin group chat
- AI-assisted content creation
- A plugin SDK for extensibility

**It is not a SaaS.** There is one tenant. The database is a private island.

The public-facing brand is **VybeCod.ing**. The admin product is **VybeDeck CMS**.
The accent colour throughout is `#e8440a` (a warm ember orange).

---

## 2. Repository & Environment

| Item | Value |
|------|-------|
| Repo path (Windows) | `C:\DEV\VybeDeck\vybedeck_cms` |
| GitHub remote | `https://github.com/Vybecode-LTD/VybeDeckCMS.git` |
| Active branch | `main` (everything is merged here) |
| Deployment | Railway — auto-deploys when `main` is pushed |
| Ruby | 3.4.x (managed under `C:\DEV\VybeDeck\.tools\Ruby34\`) |
| Rails | 8.1.x |
| PostgreSQL | 17 (managed under `C:\DEV\VybeDeck\.tools\PostgreSQL17\`) |
| Node / npm | NOT present — Importmap handles JS, no build step |

### Windows PATH prefix (required before every Rails command)

```powershell
$env:PATH='C:\DEV\VybeDeck\.tools\Ruby34\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\ucrt64\bin;C:\DEV\VybeDeck\.tools\Ruby34\msys64\usr\bin;C:\DEV\VybeDeck\.tools\PostgreSQL17\bin;' + $env:PATH
cd C:\DEV\VybeDeck\vybedeck_cms
```

Without this prefix, `ruby`, `gem`, `bundle`, and `psql` commands will not be found.

### Starting the dev server

```powershell
ruby bin\rails server        # http://localhost:3000
ruby bin\rails test          # run the full test suite
ruby bin\rails db:seed       # idempotent seed (safe to run multiple times)
ruby bin\rails db:migrate    # run pending migrations
```

---

## 3. First Thing To Do Every Session

```powershell
# 1. Set PATH (see above)
# 2. Confirm baseline is green — DO NOT start work on red tests
ruby bin\rails test
# Expected: 29 runs, 141 assertions, 0 failures, 0 errors, 0 skips

# 3. Read CLAUDE.md for the current task
# 4. Start work
```

If tests are red when you arrive, **fix them before anything else**.
Do not assume a red test is pre-existing and safe to ignore.

---

## 4. Architecture — The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│  Railway Container (single Dockerfile)                       │
│                                                              │
│  ┌──────────┐   ┌───────────────────────────────────────┐   │
│  │ Thruster │──▶│  Puma (Rails 8.1)                     │   │
│  │ (proxy)  │   │                                        │   │
│  └──────────┘   │  ┌──────────┐  ┌───────────────────┐ │   │
│  PORT=80        │  │  Public  │  │  Admin             │ │   │
│                 │  │  Hotwire │  │  Administrate 1.0  │ │   │
│                 │  │  site    │  │  (namespace admin/) │ │   │
│                 │  └──────────┘  └───────────────────┘ │   │
│                 │                                        │   │
│                 │  Solid Queue (in-process via Puma)     │   │
│                 │  Solid Cache                           │   │
│                 │  Solid Cable (ActionCable)             │   │
│                 └───────────────────────────────────────┘   │
│                              │                               │
│                 ┌────────────▼────────────┐                  │
│                 │  PostgreSQL 17          │                  │
│                 │  (single DATABASE_URL)  │                  │
│                 │  primary + cache +      │                  │
│                 │  queue + cable configs  │                  │
│                 └─────────────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

### Why Railway (not Kamal/VPS)?

The project started with Kamal in the roadmap but was switched to Railway because:
- Railway provides PostgreSQL, HTTPS, and automatic deploys with zero infra management
- `DATABASE_URL` is a single connection string that works for all four Rails DB configs
- Railway's router expects PORT 80 — Thruster (Rails 8's built-in reverse proxy) listens on 80

**Critical:** `railway.toml` pins `PORT=80`. If you remove this, Thruster listens on a
Railway-injected random port and the healthcheck fails permanently.

### Why Propshaft (not Sprockets or Vite)?

Rails 8 ships Propshaft as the default. It is a simple file-copy pipeline with no
transformation, no bundling, no CSS processing, and no JS bundling. This means:
- CSS `@import url("...")` is resolved by the **browser**, not the pipeline
- There is no CSS minification or fingerprinting of @imports
- Google Fonts is loaded via `@import url(...)` in `application.css` — this is fine
- Stimulus controllers are loaded via Importmap — no transpilation

Do not add Webpack, esbuild, or Vite unless there is a very strong reason discussed
with the owner first.

### Why four database configs for one database?

Rails 8's Solid Queue, Solid Cache, and Solid Cable each need their own `migrations_paths`
entry in `database.yml`. They also each need their own named config (`cache:`, `queue:`,
`cable:`). Railway provides a single PostgreSQL instance and a single `DATABASE_URL`.

The solution: all four configs point to the same `url: ENV["DATABASE_URL"]` but declare
different `migrations_paths`. All tables end up in the same database — the Rails multi-DB
plumbing just routes each model class to the right config at query time.

**Never** try to give Solid Queue/Cache/Cable a separate database unless Railway provides
a second instance. The `database.yml` in production is correct as-is.

### Why is there a retry loop in `bin/docker-entrypoint`?

On first deploy, Railway starts the Rails container and the PostgreSQL container at the
same time. PostgreSQL takes several seconds to accept connections. Without the retry loop,
`db:migrate` runs before PostgreSQL is ready, gets `connection refused`, and the container
exits with code 1 — which Railway interprets as a crash.

The entrypoint retries `db:migrate` up to 12 times with 5-second gaps (60 seconds total).
Do not simplify or remove this loop.

---

## 5. Content Model — What Exists

### `Page`
Standalone or hierarchical content. Think: Home, About, Contact.

```ruby
# Key columns
slug          # FriendlyId, e.g. "home", "about"
title
body          # Action Text (rich text)
hero_image    # Active Storage attachment
status        # enum: draft(0), published(1), archived(2)
published_at  # set automatically by Publishable concern on first publish
meta_title        # Seoable concern — NOT yet output to views
meta_description  # Seoable concern — NOT yet output to views
show_in_nav   # boolean
position      # integer for nav ordering
parent_id     # self-referential for hierarchical pages
```

The homepage is the page with slug `home`. The `PagesController` maps `/` to `find_by(slug: "home")`.

### `Post`
Dated editorial content. Think: blog articles, news, journal entries.

```ruby
# Key columns
slug          # FriendlyId with history
title
body          # Action Text
excerpt       # plain text, used in post cards
cover_image   # Active Storage (single image)
gallery       # Active Storage (has_many_attached)
author_id     # FK to User
status        # enum via Publishable
published_at  # set automatically
meta_title        # Seoable — NOT yet output
meta_description  # Seoable — NOT yet output
```

Posts have a `categories` join through `Tagging` (a join model). A post can belong to
multiple categories.

### `Category`
Simple taxonomy with FriendlyId slug. Used to group posts. Public URL: `/topics/:slug`.

### `User`
```ruby
role   # enum: author(0), editor(1), admin(2)
email_address
# Missing: display_name, avatar — these are known gaps
```

The `author` role can create/edit their own content.
The `editor` role can manage all content and access admin.
The `admin` role can do everything including user management.

### Concerns
- `Publishable`: adds `status` enum, `published_at`, `live` scope, and `set_published_at_on_publish` callback
- `Seoable`: adds `meta_title` and `meta_description` string columns. **The concern is
  included in Page and Post but the fields are not yet output in any layout or view.
  This is a known gap — wiring them up is a quick win for any session.**

---

## 6. Admin Panel — Administrate 1.0

The admin is at `/admin`, gated to `editor` and `admin` roles via Pundit.

### What is customised (files you own)

```
app/dashboards/page_dashboard.rb      # COLLECTION_ATTRIBUTES, FORM_ATTRIBUTES, COLLECTION_FILTERS
app/dashboards/post_dashboard.rb      # same, plus categories
app/dashboards/category_dashboard.rb
app/dashboards/user_dashboard.rb

app/fields/active_storage_field.rb   # CUSTOM: Administrate 1.0 has no built-in file field
app/views/fields/active_storage/     # _form.html.erb and _show.html.erb for above

app/views/admin/application/_form.html.erb    # OVERRIDE: adds multipart:true to all admin forms
app/views/admin/pages/show.html.erb           # OVERRIDE: adds "View on site" / "Preview draft" button
app/views/admin/posts/show.html.erb           # OVERRIDE: same
app/views/admin/pages/_collection_item_actions.html.erb   # adds "View" to collection rows
app/views/admin/posts/_collection_item_actions.html.erb   # same
```

### The `multipart: true` override
Administrate's default `_form.html.erb` uses `form_with` without `multipart: true`, which
silently ignores file inputs. The override at `app/views/admin/application/_form.html.erb`
adds `multipart: true` to every admin form. **Every new admin form that has a file field
will work automatically because of this override. Do not remove it.**

### The `ActiveStorageField`
Administrate 1.0 (released 2024) removed the ActiveStorage field that existed in 0.x.
The project has a hand-rolled replacement. If you add a new model with an Active Storage
attachment and want to show/edit it in Administrate, add this to the dashboard:

```ruby
ATTRIBUTE_TYPES = {
  cover_image: ActiveStorageField,
  # ...
}
```

The corresponding views are already in `app/views/fields/active_storage/`.

### The `page` name collision in admin
Administrate uses a local variable called `page` for its presenter object in show views.
This clashes with Rails' `page_path` route helper which also expects a page-like object.
The workaround already in `app/views/admin/pages/show.html.erb` is:

```erb
<% cms_page = page.resource %>
<%= link_to "View", main_app.page_path(cms_page.slug) %>
```

If you ever add new admin show overrides for pages, use this pattern.

---

## 7. Public Site

The public Hotwire site uses server-rendered ERB templates with Turbo Drive for navigation.
There is no React, Vue, or client-side routing.

### Routes (relevant ones)

```ruby
root "pages#show", id: "home"           # / → pages controller, slug = home
get "/:id", to: "pages#show"            # /:slug → any page
get "/blog", to: "posts#index"
get "/blog/:id", to: "posts#show"
get "/topics/:id", to: "categories#show"
```

### Layouts

```
app/views/layouts/application.html.erb   # public site — has nav, footer, flash
app/views/layouts/auth.html.erb          # auth pages — centred card, no nav, brand only
```

SessionsController and PasswordsController use `layout "auth"`.

### Shared partials

```
app/views/shared/_site_header.html.erb   # sticky glass header, brand mark, nav, theme toggle
app/views/shared/_site_footer.html.erb   # simple footer
```

### ApplicationHelper methods used in views

```ruby
public_nav_pages      # returns published Pages with show_in_nav: true, ordered by position
page_title            # returns meta_title or title for a given record
status_label(post)    # returns human-readable status string
readable_date(date)   # returns formatted date string
```

---

## 8. Design System

All styling is in `app/assets/stylesheets/application.css`.
There is no CSS preprocessor. The file uses native CSS custom properties.

### Token system

```css
/* Light (default — :root) */
--bg:            #f8f7f5    /* page background */
--bg-elevated:   #ffffff    /* cards, inputs */
--bg-sunken:     #f0eee9    /* code blocks, inner wells */
--bg-overlay:    rgba(255,255,255,.88)   /* header glass */
--border:        #e4e1da
--border-strong: #cac7be
--text:          #18150e
--text-muted:    #6b6860
--text-faint:    #a8a49b
--accent:        #e8440a    /* VybeCod.ing ember — never change this */
--accent-hover:  #cf3d09
--accent-soft:   #f06030
--accent-bg:     #fff3ef
--accent-border: #f5c0aa

/* Dark — applied via @media (prefers-color-scheme: dark) AND [data-color-scheme="dark"] */
--bg:            #0f0e0d
--bg-elevated:   #1a1816
--bg-sunken:     #0b0a09
--bg-overlay:    rgba(15,14,13,.9)
/* ... see application.css for full dark token set */
```

### How theme switching works

1. `<html data-color-scheme="">` — the attribute is empty by default
2. A no-flash inline `<script>` in `<head>` reads `localStorage.getItem("vyb-color-scheme")`
   before first paint and sets the attribute to `"dark"` or `"light"` if stored
3. CSS uses `@media (prefers-color-scheme: dark) { :root:not([data-color-scheme="light"]) }`
   for system preference
4. CSS uses `[data-color-scheme="dark"]` for the manual override
5. The theme toggle button in the site header toggles the attribute and writes to localStorage

**Do not add `prefers-color-scheme` media queries to individual component CSS rules.**
All theming is done via custom property overrides on `:root`. Components always use
`var(--token-name)` and automatically get the right value.

### Adding new components

Follow this pattern:

```css
.my-component {
  background: var(--bg-elevated);
  border: 1px solid var(--border);
  border-radius: var(--radius);     /* --radius-sm: 8px, --radius: 12px, --radius-lg: 16px */
  color: var(--text);
  font-family: inherit;             /* inherits Inter from body */
}

.my-component:hover {
  border-color: var(--border-strong);
  box-shadow: var(--shadow-md);
}

.my-component:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 3px;
}
```

**Never hard-code a colour value in a component rule.** Always use a `--token`.

### CSS classes already defined (do not reinvent)

```
Layout:        .shell, .reading-width, .page-shell
Header:        .site-header, .site-header__inner, .brand-mark, .brand-mark__sigil, .site-nav
Buttons:       .btn, .btn--secondary, .btn--ghost, .btn--full
Forms:         .form-field (wrapper with label + input)
Cards:         .post-card, .post-card__media, .post-card__body
Typography:    .eyebrow, .lede, .byline
Content:       .content-hero, .content-hero__grid, .content-hero__copy, .content-band
Media:         .feature-media
Taxonomy:      .topic-chip, .topic-list
Status:        .status-pill
Auth:          .auth-shell, .auth-card, .auth-card__header, .auth-form, .auth-footer, .auth-brand
Flash:         .flash, .flash--notice, .flash--alert
Rich text:     .trix-content
Footer:        .site-footer, .site-footer__inner
Toggle:        .theme-toggle, .icon-sun, .icon-moon
```

---

## 9. Testing

The project uses **Minitest** throughout. Do not introduce RSpec.

### Run the suite

```powershell
ruby bin\rails test                    # all tests
ruby bin\rails test test/models/       # models only
ruby bin\rails test test/integration/  # integration only
ruby bin\rails test test/models/post_test.rb  # single file
```

### Rules
- Every new model needs a test file under `test/models/`
- Every new controller action needs coverage in `test/integration/`
- Every bug fix needs a test that **fails before the fix** and **passes after**
- New migrations do not need their own tests — model tests cover the resulting schema

### Current test files

```
test/models/active_storage_variant_test.rb     # proves variant jobs enqueue (not transform)
test/integration/public_cms_routes_test.rb     # homepage, blog, topic, page show — all 200
test/integration/admin_access_test.rb          # role gating on admin routes
test/integration/admin_content_management_test.rb  # CRUD through admin
test/integration/seeds_test.rb                 # idempotency of db:seed
```

### Known gap in test coverage
- No tests for the auth pages (sign-in, forgot password, reset password)
- No tests for the design system or CSS output
- No tests for the theme toggle behaviour

---

## 10. Deployment Pipeline

### Normal deploy
```powershell
git push origin main    # Railway picks this up automatically
```

Railway builds the Dockerfile, pulls gems, runs `bin/docker-entrypoint`, starts Puma.
The entrypoint runs `db:migrate` (with retry loop) before the server starts.
There are no manual deploy steps.

### Environment variables on Railway (never commit these)

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string (set by Railway) |
| `RAILS_MASTER_KEY` | Decrypts credentials.yml.enc |
| `RAILS_ENV` | Set to `production` |
| `RAILS_ALLOWED_HOSTS` | Comma-separated extra allowed hostnames |
| `RAILS_HOST` | Used for Action Mailer `default_url_options` |

Future variables to add (not yet needed):
- `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET` (Phase 3)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` (Phase 1 S3)
- `ANTHROPIC_API_KEY` (Phase 7)
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` (any phase, for email)

### Files critical to deployment

```
railway.toml              # PORT=80 is CRITICAL. healthcheckTimeout=600. Do not simplify.
Dockerfile                # Standard Rails 8 image. libvips needs to be added (known gap).
bin/docker-entrypoint     # Retry loop for db:migrate. Do not remove or simplify.
config/database.yml       # Production section: all 4 configs share DATABASE_URL.
config/environments/production.rb  # assume_ssl, force_ssl, Railway hosts allowed.
```

---

## 11. Known Gaps — Priority Order

These are the things that need fixing, ordered by impact. A new session should pick
from the top of this list unless the owner has directed otherwise.

### P1 — Blocks production use

**`libvips` not in Dockerfile**
Active Storage image variants are defined on Page and Post models but the transform
jobs enqueue successfully and then fail silently in production because `libvips` is not
installed in the Docker image. Add to `Dockerfile`:

```dockerfile
RUN apt-get update -qq && apt-get install -y libvips && rm -rf /var/lib/apt/lists/*
```
Add it before the `bundle install` step so gem compilation can detect it.

**Active Storage on local volume (not S3)**
The current `config/storage.yml` uses `local` service. In Railway, the container
filesystem is ephemeral — files uploaded in one deploy are gone in the next unless
you mount a persistent volume. For anything that matters, set up S3 storage:

```yaml
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: <%= ENV["AWS_REGION"] %>
  bucket: <%= ENV["AWS_BUCKET"] %>
```

And in `config/environments/production.rb`:
```ruby
config.active_storage.service = :amazon
```

Add `aws-sdk-s3` to the Gemfile. Set the four `AWS_*` env vars on Railway.

### P2 — Content quality

**`Seoable` concern not wired to views**
`Page` and `Post` both have `meta_title` and `meta_description` columns via the
`Seoable` concern. Neither field is currently output anywhere. The fix is small:

In `app/views/layouts/application.html.erb`, replace the title tag with:
```erb
<title><%= content_for(:title).presence || (defined?(@page) && @page&.meta_title.presence) || (defined?(@post) && @post&.meta_title.presence) || "VybeDeck CMS" %></title>
<meta name="description" content="<%= (defined?(@page) && @page&.meta_description) || (defined?(@post) && @post&.meta_description) || "" %>">
```

A cleaner approach is a `seo_tags` helper in `ApplicationHelper`.

**`display_name` missing on User**
Post bylines currently show `current_user.email_address` publicly. Add a migration:
```ruby
add_column :users, :display_name, :string
```
Update the post byline partial to use `post.author.display_name.presence || post.author.email_address.split("@").first`.

### P3 — Editorial quality

**No pagination**
The blog index (`/blog`) and category pages (`/topics/:slug`) return all posts.
Add `pagy` gem and paginate with `pagy(@posts, items: 12)`.

**No empty states**
When a category has no published posts, the page renders an empty list with no message.
Add a conditional in the category and blog views.

**No SMTP for password reset**
The "Forgot password" flow creates the reset token and calls `deliver_later` but the
mail never arrives in production. Configure Action Mailer in `production.rb` and set
`SMTP_*` env vars on Railway.

---

## 12. Immediate Next Work — Phase 1 Media Manager

The next major feature is the **Media Manager** (ROADMAP.md Phase 1).
Here is a specific, ordered task list for the agent starting this work:

### Step 1: Dockerfile — add libvips (30 min)

This is the highest-impact change per effort. Do it first.

```dockerfile
# In Dockerfile, find the apt-get section and add libvips:
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev libvips && \
    rm -rf /var/lib/apt/lists/*
```

Run `ruby bin\rails test` after — no tests should break.
Commit: `fix(docker): add libvips for Active Storage image processing`

### Step 2: Switch to S3 storage (2 hours)

1. Add `gem "aws-sdk-s3", require: false` to Gemfile
2. Run `bundle install`
3. Update `config/storage.yml` with amazon service (see above)
4. Update `config/environments/production.rb` to use `:amazon`
5. Keep `config/environments/development.rb` on `:local`
6. Set `AWS_*` env vars on Railway (get credentials from owner)
7. Write a test that confirms `ActiveStorage::Blob` can be created in test env
8. Commit: `feat(storage): configure S3 for production Active Storage`

### Step 3: Wire Seoable to views (1 hour, high value quick win)

1. Add `seo_tags` helper to `ApplicationHelper`
2. Update `application.html.erb` title tag and add meta description tag
3. Write a test that confirms the title and description appear in the response
4. Commit: `feat(seo): wire Seoable concern to layout title and meta description`

### Step 4: Add display_name to User (30 min)

1. Generate migration: `ruby bin\rails generate migration AddDisplayNameToUsers display_name:string`
2. Add validation: `validates :display_name, length: { maximum: 60 }, allow_blank: true`
3. Update seed to set `display_name` on the admin user
4. Update post byline partial
5. Add `display_name` to `UserDashboard` FORM_ATTRIBUTES
6. Write a test
7. Commit: `feat(user): add display_name to replace email in public bylines`

### Step 5: Build the Medium model (half day)

The `Medium` model is the heart of the Media Manager. Design:

```ruby
# migration
create_table :media do |t|
  t.string    :title, null: false
  t.string    :alt_text
  t.text      :caption
  t.string    :media_type, null: false   # image, audio, video, document
  t.references :uploaded_by, foreign_key: { to_table: :users }
  t.timestamps
end

# model
class Medium < ApplicationRecord
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file

  enum :media_type, { image: "image", audio: "audio", video: "video", document: "document" }

  validates :title, presence: true
  validates :media_type, presence: true

  ACCEPTED_TYPES = {
    image:    %w[image/jpeg image/png image/gif image/webp image/avif image/svg+xml],
    audio:    %w[audio/mpeg audio/wav audio/flac audio/aac audio/ogg],
    video:    %w[video/mp4 video/avi video/quicktime video/webm],
    document: %w[application/pdf application/vnd.openxmlformats-officedocument.wordprocessingml.document text/plain application/zip]
  }.freeze

  def self.type_for_mime(mime)
    ACCEPTED_TYPES.find { |type, mimes| mimes.include?(mime) }&.first&.to_s
  end
end
```

Write: model tests, admin dashboard (`MediaDashboard`), admin route in `routes.rb`.

### Step 6: Admin media library UI

After the model exists, build the library grid:
- `admin/media#index` — grid view, filterable by type, paginated with Pagy
- `admin/media#new` — drag-and-drop upload using a Stimulus controller
- `admin/media#show` — preview, metadata, edit alt text/caption
- `admin/media#destroy` — with confirmation

The Stimulus drag-and-drop controller:
```javascript
// app/javascript/controllers/file_drop_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "label"]

  drop(event) {
    event.preventDefault()
    const files = event.dataTransfer.files
    this.inputTarget.files = files
    this.showPreview(files[0])
  }

  change(event) {
    this.showPreview(event.target.files[0])
  }

  showPreview(file) {
    if (!file) return
    this.labelTarget.textContent = file.name
  }
}
```

### Step 7: Audio player component

After media uploads work, build the audio player:

```erb
<%# app/views/shared/_audio_player.html.erb %>
<div class="audio-player" data-controller="audio-player">
  <audio data-audio-player-target="audio" preload="metadata"
         src="<%= rails_blob_url(medium.file) %>"></audio>
  <div class="audio-player__controls">
    <button data-action="click->audio-player#togglePlay" class="audio-player__play">
      <%# play/pause icon via data-audio-player-playing-value %>
    </button>
    <div class="audio-player__scrubber">
      <input type="range" min="0" value="0" step="0.01"
             data-audio-player-target="scrubber"
             data-action="input->audio-player#seek">
    </div>
    <span class="audio-player__time" data-audio-player-target="time">0:00</span>
  </div>
  <p class="audio-player__title byline"><%= medium.title %></p>
</div>
```

The Stimulus controller for this is `app/javascript/controllers/audio_player_controller.js`.
Wire up: play/pause toggle, scrubber sync, time display.

---

## 13. Things That Will Bite You If You Forget

### The four-database pattern in production
When adding a new model that uses `connects_to`, make sure it maps to the right config
in `database.yml`. Solid Queue, Cache, and Cable each have their own connection.
**Regular app models always use the primary connection — you don't need `connects_to`.**

### Pundit: every action needs a policy
The `ApplicationController` calls `verify_authorized` after actions. If you add a new
controller action and forget to call `authorize @record`, tests will fail with a
`Pundit::AuthorizationNotPerformedError`. Always add a policy class when you add
a new model with admin routes.

### Administrate `page` naming
The Administrate presenter variable is named `page` in all resource views. If your
resource is literally a `Page` model, alias it immediately at the top of any overridden view:

```erb
<% cms_page = page.resource %>
```

### `multipart: true` on new admin forms
The override in `app/views/admin/application/_form.html.erb` adds `multipart: true`
to all admin forms. You get this for free on existing forms. If you ever create a
completely custom form in an admin view that does NOT inherit from the application
form partial, remember to add `multipart: true` yourself.

### Seeding does not run on deploy
The `bin/docker-entrypoint` runs `db:migrate` but NOT `db:seed`. Seeds only run
when you explicitly call `ruby bin\rails db:seed`. This is intentional: production
data must not be overwritten by seeds on every deploy.

### Never use `git add -A` or `git add .`
The `storage/` directory, `tmp/`, `log/`, and `.claude/` contain local state that
must not be committed. Always stage files by name. Check `git status` and `git diff`
before every commit.

### The `.claude/launch.json` file
There is a `C:\DEV\VybeDeck\vybedeck_cms\.claude\launch.json` used for the Preview
MCP tool (screenshot previews in development). It contains absolute Windows paths.
It should NOT be committed. Add `.claude/` to `.gitignore` if it isn't already.

---

## 14. Commit Convention

All commits use conventional format:

```
type(scope): short description

Body (optional): what and why, not how.
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change with no behaviour change |
| `test` | Adding or fixing tests |
| `chore` | Dependency updates, config, build |
| `style` | CSS/design changes |

Scopes in use: `(design)`, `(admin)`, `(deploy)`, `(auth)`, `(public)`, `(media)`,
`(user)`, `(commerce)`, `(forum)`, `(chat)`, `(album)`, `(ai)`, `(plugin)`, `(seo)`

---

## 15. Quick Reference — Seed Credentials

| Field | Value |
|-------|-------|
| Admin email | `admin@vybedeck.test` |
| Admin password | `password` |
| Admin URL | `http://localhost:3000/admin` |
| Sign-in URL | `http://localhost:3000/session/new` |

---

## 16. Who To Ask (for humans reading this)

All architectural decisions in this file were made in coordination with the project
owner at Vybecode Ltd. If you are unsure whether a change conflicts with the vision
described here, ask before implementing. The guiding principle is:

> **One monolith, one database, server-rendered Hotwire, minimal dependencies.**
> Reach for a new gem only when the standard library genuinely cannot do the job.
