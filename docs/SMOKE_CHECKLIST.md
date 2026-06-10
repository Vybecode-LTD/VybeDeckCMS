# Production Smoke Checklist

Run this checklist after every deploy to `main` on Railway before declaring the release healthy.

---

## 1. Application boot

- [ ] Railway deploy log shows `Started GET "/up"` with HTTP 200 (health check passes)
- [ ] No `Error loading boot file` or `uninitialized constant` in deploy log
- [ ] `db:migrate` reports `migrating` or `already up to date` (not an error)
- [ ] `db:seed` reports completion (admin user and structural pages seeded)

---

## 2. Public site

| URL | Expected result |
|-----|-----------------|
| `https://yourdomain.example/` | Home page renders with VybeCod.ing styling |
| `https://yourdomain.example/blog` | Blog index lists published posts |
| `https://yourdomain.example/pages/about` | About page renders |
| `https://yourdomain.example/sitemap.xml` | Valid XML with at least one `<url>` |
| `https://yourdomain.example/robots.txt` | Contains `Disallow: /admin` |

- [ ] All five URLs return HTTP 200
- [ ] No Propshaft 404s in browser Network tab (check `application.css`, `application.js`)
- [ ] Images load (cover images, hero images are not broken)

---

## 3. Authentication

- [ ] `GET /login` renders the login form
- [ ] Sign in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` → redirects to root or `/admin`
- [ ] Session persists on page reload
- [ ] Sign out clears the session and redirects to `/login`
- [ ] Attempting `GET /admin` while signed out redirects to `/login`

---

## 4. Admin panel

- [ ] `GET /admin` renders the Administrate dashboard as admin
- [ ] Post list loads and shows at least one row
- [ ] Page list loads and shows Home and About
- [ ] Create a new draft post, verify it appears in the admin list but not the public blog
- [ ] Publish the post, verify it appears on the public blog
- [ ] Delete the test post

---

## 5. Active Storage

- [ ] Upload an image via the admin post editor (cover image field)
- [ ] The image appears in the admin view
- [ ] The image is served from the R2 bucket URL (inspect the `src` attribute — should be a Cloudflare R2 URL, not a local `/rails/active_storage/` URL in production)
- [ ] No 403 or 404 from R2 when loading the image

---

## 6. Background jobs (Solid Queue)

- [ ] After uploading an image, check Railway logs for `[SolidQueue]` job started/finished lines
- [ ] Active Storage variant generation job completes (no `failed_executions` row in `solid_queue_failed_executions` table)
- [ ] Check via Rails console: `SolidQueue::FailedExecution.count` → `0`

---

## 7. Email delivery

- [ ] Trigger a password reset for the admin account (`/passwords/new`)
- [ ] Email arrives in the inbox within 60 seconds
- [ ] Reset link in the email is correct (`https://yourdomain.example/...`)

---

## 8. Stripe integration

- [ ] `GET /checkout` (or your product purchase page) renders without error
- [ ] Stripe.js loads (check Network tab for `js.stripe.com`)
- [ ] Complete a test purchase with Stripe test card `4242 4242 4242 4242`, any future expiry, any CVC
- [ ] Order confirmation page or redirect renders after payment
- [ ] Stripe dashboard shows the test payment
- [ ] Webhook delivery shows `200` in the Stripe dashboard (Webhooks → Event log)

---

## 9. Theme

- [ ] `GET /admin/theme` renders the theme editor
- [ ] Edit a colour token, click Save — public site CSS updates within a few seconds (Solid Cache TTL)

---

## 10. SEO meta

- [ ] View source on the home page — confirm `<title>`, `<meta name="description">`, `<link rel="canonical">`, OG tags, Twitter Card tags are present
- [ ] Google Rich Results Test passes for the home page URL (optional, post-launch)

---

## Rollback criteria

Roll back the deploy immediately if any of the following are true:

- Admin login is broken
- Public home page returns 500
- Database migrations rolled back or errored
- Stripe webhook returns non-200 from the application
- Active Storage uploads fail with 500

---

## After smoke passes

- [ ] Change the admin password from the default if this is a first deploy
- [ ] Confirm `ADMIN_PASSWORD` env var is updated in Railway
- [ ] Tag the release: `git tag v$(date +%Y.%m.%d) && git push origin --tags`
