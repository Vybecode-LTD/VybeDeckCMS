# Active Storage Backup Strategy

All uploaded media (cover images, hero images, gallery attachments) is stored in
Cloudflare R2. This document describes the backup posture and recovery procedure.

---

## Storage configuration

| Environment | Backend | Config key |
|-------------|---------|------------|
| Production  | Cloudflare R2 | `:cloudflare` (in `config/storage.yml`) |
| Development | Local disk | `:local` |
| Test        | Local disk | `:test` |

The R2 bucket name is set via `CLOUDFLARE_R2_BUCKET` env var (see
`.env.production.example`).

---

## Backup strategy — R2 bucket versioning

Cloudflare R2 supports **Object Versioning** at the bucket level.

### Enable versioning (one-time setup)

1. Cloudflare dashboard → R2 → your bucket → Settings → Object versioning → **Enable**.
2. Versioning is bucket-wide and applies to all existing and future objects.

With versioning enabled, overwriting or deleting an object creates a new version
rather than permanently destroying the previous one. Objects can be restored from
the Cloudflare dashboard or via the S3-compatible API.

### Retention policy

| Version age | Action |
|-------------|--------|
| Current     | Keep indefinitely |
| Deleted / overwritten | Retain for 30 days |

Configure this via an R2 **Lifecycle rule** (Bucket → Settings → Lifecycle):

```
Prefix: (empty — applies to all objects)
Action: Delete expired object versions
Days after version becomes non-current: 30
```

This balances recovery window against storage cost.

---

## Cross-region redundancy (optional, higher tier)

Cloudflare R2 stores objects with multiple replicas within its network by
default. For additional geo-redundancy or a second provider backup:

- Enable **Jurisdiction-restricted storage** in Cloudflare for data-residency
  compliance if required.
- For a second provider mirror, use `rclone sync` from a scheduled Railway
  cron job to an AWS S3 or Backblaze B2 bucket. Example cron job body:

  ```bash
  rclone sync r2:vybedeck-cms-production b2:vybedeck-cms-backup \
    --s3-access-key-id $CLOUDFLARE_R2_ACCESS_KEY_ID \
    --s3-secret-access-key $CLOUDFLARE_R2_SECRET_ACCESS_KEY \
    --s3-endpoint https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com
  ```

---

## Database backup

Active Storage metadata (filenames, content types, blob keys) is stored in the
PostgreSQL `active_storage_blobs` and `active_storage_attachments` tables.

Railway's Postgres plugin provides **daily automated backups** with a 7-day
retention window by default. Verify this in:
Railway dashboard → your project → Postgres → Backups.

### Point-in-time restore

To restore a specific database backup:
1. Railway → Postgres → Backups → choose the backup → Restore.
2. After restore, any blobs whose R2 objects were deleted in the interim will
   return 404 errors. Re-upload via the admin panel or restore from the R2
   versioned backup.

---

## Recovery procedure

### Scenario: accidental file deletion via admin

1. In Cloudflare R2, navigate to the bucket → Objects → show deleted objects.
2. Locate the object by its blob key (visible in the Rails console:
   `ActiveStorage::Blob.find_by(filename: "example.jpg").key`).
3. Restore the previous version from the R2 dashboard.
4. The attachment reference in PostgreSQL is already intact; no DB action needed.

### Scenario: corrupted production database

1. Restore from Railway backup (see above).
2. R2 objects are unaffected — they persist independently.
3. If the restore point is older than new uploads, those blobs will reference
   R2 objects that still exist (R2 has them even though the DB row was rolled
   back). Clean up orphaned blobs after stabilisation:
   ```ruby
   # Rails console — dry run first
   ActiveStorage::Blob.where.missing(:attachments).find_each do |blob|
     puts blob.key
   end
   # Then: ActiveStorage::Blob.where.missing(:attachments).each(&:purge)
   ```

### Scenario: entire R2 bucket accidentally deleted

1. R2 does not allow deleting a bucket with objects when versioning is enabled
   (the bucket must be empty first). This scenario requires deliberate action.
2. If it happens: restore from the rclone mirror (if configured) or contact
   Cloudflare support — versioned objects may be recoverable at the
   infrastructure level.

---

## Monitoring

- Set up a Cloudflare R2 usage alert (Dashboard → Notifications) to catch
  unexpected storage growth (potential scraper, runaway upload loop).
- Check `SolidQueue::FailedExecution.where("job_class LIKE '%ActiveStorage%'").count`
  periodically to confirm no variant generation jobs are silently failing.
