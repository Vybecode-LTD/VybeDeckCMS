require "test_helper"

# Tests for the shared audio player partial and its integration in the admin
# media show page.  These are server-rendered checks (the Stimulus JS is not
# exercised here — that would need a system / browser test).
class AudioPlayerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-audio-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :admin
    )
    @editor = User.create!(
      email_address: "editor-audio-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :editor
    )
  end

  # ── helpers ─────────────────────────────────────────────────────────────────

  def create_audio_medium(user:)
    m = Medium.new(title: "Test Track", file_type: :audio, uploaded_by: user)
    m.file.attach(
      io:           StringIO.new("ID3" + ("x" * 200)),
      filename:     "track.mp3",
      content_type: "audio/mpeg"
    )
    m.save!
    m
  end

  def create_image_medium(user:)
    m = Medium.new(title: "Test Image", file_type: :image, uploaded_by: user)
    m.file.attach(
      io:           StringIO.new("\x89PNG\r\n\x1a\n" + ("x" * 100)),
      filename:     "photo.png",
      content_type: "image/png"
    )
    m.save!
    m
  end

  # ── admin show page — audio medium renders player ──────────────────────────

  test "admin show page renders audio player for audio medium" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='audio-player']", count: 1
  end

  test "admin show page renders audio element with correct source" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "audio[data-audio-player-target='audio']", count: 1
    assert_select "audio source[type='audio/mpeg']", count: 1
  end

  test "admin show page renders play button" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "button[data-audio-player-target='playBtn']", count: 1
    assert_select "button[aria-label='Play']", count: 1
  end

  test "admin show page renders scrubber input" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "input[data-audio-player-target='scrubber']", count: 1
  end

  test "admin show page renders speed selector" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "select[data-audio-player-target='speed']", count: 1
  end

  test "admin show page renders volume slider" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select "input[data-audio-player-target='volume']", count: 1
  end

  test "admin show page does NOT render audio player for image medium" do
    sign_in_as @admin
    medium = create_image_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='audio-player']", count: 0
  end

  test "editor can see audio player on show page" do
    sign_in_as @editor
    medium = create_audio_medium(user: @editor)

    get admin_medium_path(medium)

    assert_response :ok
    assert_select "[data-controller='audio-player']", count: 1
  end

  # ── partial renders title ──────────────────────────────────────────────────

  test "audio player shows the medium title" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_select ".audio-player__title", text: medium.title
  end

  # ── show_download behaviour ────────────────────────────────────────────────

  # Admin show embeds the player with show_download: false, so no download link
  # in the preview area — the download link is already in the attributes table.
  test "audio player preview does not show download link when show_download is false" do
    sign_in_as @admin
    medium = create_audio_medium(user: @admin)

    get admin_medium_path(medium)

    assert_response :ok
    # The .audio-player__download link should not be present in the player
    assert_select ".audio-player .audio-player__download", count: 0
  end
end
