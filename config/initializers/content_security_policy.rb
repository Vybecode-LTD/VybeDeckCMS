# Content Security Policy
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# Notes on the current policy:
#   - script-src uses nonces (generated per-request) so the no-flash theme
#     inline script and importmap tags work without 'unsafe-inline'.
#   - style-src includes 'unsafe-inline' because Propshaft renders inline
#     <style> blocks and some views use style="" attributes; tighten later.
#   - frame-src is the enforcement surface for embed widgets (Phase 1.4).
#     Add new providers here — nowhere else.
#   - media-src covers Active Storage presigned S3 URLs and blob: for
#     WebAudio use.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    # Scripts — nonce injected automatically by Rails for importmap tags and
    # any tag that uses content_security_policy_nonce in the view.
    # strict-dynamic allows modules loaded by nonce-trusted scripts (Importmap).
    policy.script_src :self, :strict_dynamic

    # Styles — unsafe-inline required while inline style="" attributes exist
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com"

    # Fonts (Google Fonts CDN)
    policy.font_src :self, :data, "https://fonts.gstatic.com"

    # Images — https for remote, data: for base64 inline, blob: for canvas
    policy.img_src :self, :https, :data, :blob

    # Ajax / WebSocket (Action Cable via Solid Cable)
    policy.connect_src :self

    # Audio + video from Active Storage (disk or S3) and blob: for Web Audio
    policy.media_src :self, :https, :blob

    # Disallow Flash / Java plugins
    policy.object_src :none

    # Web Workers (used by some JS libraries)
    policy.worker_src :blob

    # ── Embed widget frame sources ────────────────────────────────────────────
    # When adding a new embed provider, add its iframe origin here.
    policy.frame_src(
      "https://www.youtube.com",
      "https://player.vimeo.com",
      "https://open.spotify.com",
      "https://w.soundcloud.com",
      "https://embed.music.apple.com"
    )
  end

  # Nonce generator: use the stable session ID so nonces survive page caching.
  config.content_security_policy_nonce_generator =
    ->(request) { request.session.id.to_s }

  # Apply nonces to script-src only (not style-src — we use unsafe-inline there).
  config.content_security_policy_nonce_directives = %w[script-src]
end
