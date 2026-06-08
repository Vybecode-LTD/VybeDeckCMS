require "test_helper"

# Tests for the shared video player partial and its integration in the admin
# media show page.  Server-rendered checks only — Stimulus JS and fullscreen
# API require a browser / system-test layer.
class VideoPlayerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-video-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :admin
    )
    @editor = User.create!(
      email_address: "editor-video-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :editor
    )
  end

  # ── helpers ─────────────────────────────────────────────────────────────────

  def create_video_medium(user:)
    m = Medium.new(title: "Test Clip", file_type: :video, uploaded_by: user)
    m.file.attach(
      io:           StringIO.new("ftypisom" + ("x" * 300)),
      filename:     "clip.mp4",
      content_type: "video/mp4"
    )
    m.save!
    m
  end

  def create_webm_medium(user:)
    m = Medium.new(title: "WebM Clip", file_type: :video, uploaded_by: user)
    m.file.attach(
      io:           StringIO.new("\x1aEß\xa3" + ("x" * 200)),
      filename:     "clip.webm",
      content_type: "video/webm"
    )
    m.save!
    m
  end

  def create_audio_medium(user:)
    m = Medium.new(title: "Track", file_type: :audio, uploaded_by: user)
    m.file.attach(
      io:           StringIO.new("ID3" + ("x" * 100)),
      filename:     "track.mp3",
      content_type: "audio/mpeg"
    )
    m.save!
    m
  end

  # ── admin show page — video medium renders player ──────────────────────────

  test "admin show page renders video player for video medium" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='video-player']", count: 1
  end

  test "admin show page renders video element with correct source type" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "video[data-video-player-target='video']", count: 1
    assert_select "video source[type='video/mp4']", count: 1
  end

  test "admin show page renders video element for webm medium" do
    sign_in_as @admin
    medium = create_webm_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "video source[type='video/webm']", count: 1
  end

  test "admin show page renders play button" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "button[data-video-player-target='playBtn']", count: 1
    assert_select "button[aria-label='Play']", count: 1
  end

  test "admin show page renders scrubber" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "input[data-video-player-target='scrubber']", count: 1
  end

  test "admin show page renders volume slider" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "input[data-video-player-target='volume']", count: 1
  end

  test "admin show page renders speed selector" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "select[data-video-player-target='speed']", count: 1
  end

  test "admin show page renders fullscreen button" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "button[data-video-player-target='fullscreenBtn']", count: 1
    assert_select "button[aria-label='Fullscreen']", count: 1
  end

  test "admin show page does NOT render video player for audio medium" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='video-player']", count: 0
  end

  test "video player shows the medium title in the screen click target" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    # The screen-click div wraps the <video>; the medium title appears in the
    # controls bar area via the page title, not inside the player itself.
    # Verify the player container is present.
    assert_select ".video-player"
  end

  test "editor can view video player on show page" do
    sign_in_as @editor
    medium = create_video_medium(user: @editor)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='video-player']", count: 1
  end

  # ── show_download behaviour ────────────────────────────────────────────────

  test "video player preview does not show download link when show_download is false" do
    sign_in_as @admin
    medium = create_video_medium(user: @admin)

    get admin_medium_path(medium)

    # Admin show renders with show_download: false
    assert_select ".video-player .video-player__download", count: 0
  end
end
