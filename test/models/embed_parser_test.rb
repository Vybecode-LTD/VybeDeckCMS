require "test_helper"

class EmbedParserTest < ActiveSupport::TestCase
  # ── nil / blank ─────────────────────────────────────────────────────────────

  test "returns nil for blank URL" do
    assert_nil EmbedParser.parse("")
    assert_nil EmbedParser.parse(nil)
  end

  test "returns nil for unrecognised URL" do
    assert_nil EmbedParser.parse("https://example.com/watch?v=abc123")
    assert_nil EmbedParser.parse("not-a-url")
  end

  # ── YouTube ──────────────────────────────────────────────────────────────────

  test "parses youtube.com watch URL" do
    result = EmbedParser.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert_equal :youtube, result.provider
    assert_includes result.embed_url, "dQw4w9WgXcQ"
    assert_equal "16 / 9", result.aspect
    assert_nil result.height
  end

  test "parses youtu.be short URL" do
    result = EmbedParser.parse("https://youtu.be/dQw4w9WgXcQ")
    assert_equal :youtube, result.provider
    assert_includes result.embed_url, "dQw4w9WgXcQ"
  end

  test "parses youtube.com without www" do
    result = EmbedParser.parse("https://youtube.com/watch?v=abc123")
    assert_equal :youtube, result.provider
    assert_includes result.embed_url, "abc123"
  end

  test "parses youtube playlist URL" do
    result = EmbedParser.parse("https://www.youtube.com/playlist?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG")
    assert_equal :youtube, result.provider
    assert_includes result.embed_url, "videoseries"
    assert_includes result.embed_url, "PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG"
  end

  test "youtube embed URL contains rel=0" do
    result = EmbedParser.parse("https://youtu.be/dQw4w9WgXcQ")
    assert_includes result.embed_url, "rel=0"
  end

  test "returns nil for youtube.com with no video id" do
    assert_nil EmbedParser.parse("https://www.youtube.com/watch")
    assert_nil EmbedParser.parse("https://www.youtube.com/")
  end

  # ── Vimeo ────────────────────────────────────────────────────────────────────

  test "parses vimeo.com URL" do
    result = EmbedParser.parse("https://vimeo.com/76979871")
    assert_equal :vimeo, result.provider
    assert_includes result.embed_url, "76979871"
    assert_equal "16 / 9", result.aspect
  end

  test "parses vimeo.com with www" do
    result = EmbedParser.parse("https://www.vimeo.com/76979871")
    assert_equal :vimeo, result.provider
    assert_includes result.embed_url, "76979871"
  end

  test "returns nil for vimeo URL with no numeric id" do
    assert_nil EmbedParser.parse("https://vimeo.com/channels/staffpicks")
  end

  # ── Spotify ──────────────────────────────────────────────────────────────────

  test "parses spotify track URL" do
    result = EmbedParser.parse("https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh")
    assert_equal :spotify, result.provider
    assert_includes result.embed_url, "/embed/track/"
    assert_equal 152, result.height
    assert_nil result.aspect
  end

  test "parses spotify album URL" do
    result = EmbedParser.parse("https://open.spotify.com/album/1uyf3l2d4XYwiEqAb7t7fX")
    assert_equal :spotify, result.provider
    assert_includes result.embed_url, "/embed/album/"
    assert_equal 352, result.height
  end

  test "parses spotify playlist URL" do
    result = EmbedParser.parse("https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
    assert_equal :spotify, result.provider
    assert_includes result.embed_url, "/embed/playlist/"
    assert_equal 352, result.height
  end

  test "returns nil for unrecognised spotify path" do
    assert_nil EmbedParser.parse("https://open.spotify.com/user/spotify")
  end

  # ── SoundCloud ───────────────────────────────────────────────────────────────

  test "parses soundcloud URL" do
    result = EmbedParser.parse("https://soundcloud.com/artistname/trackname")
    assert_equal :soundcloud, result.provider
    assert_includes result.embed_url, "w.soundcloud.com/player/"
    assert_equal 166, result.height
    assert_nil result.aspect
  end

  test "soundcloud embed URL encodes the original URL" do
    original = "https://soundcloud.com/artist/track"
    result   = EmbedParser.parse(original)
    assert_includes result.embed_url, CGI.escape(original)
  end

  test "returns nil for www.soundcloud.com" do
    # bare_host strips www — should still match
    result = EmbedParser.parse("https://www.soundcloud.com/artist/track")
    assert_equal :soundcloud, result.provider
  end

  # ── Apple Music ──────────────────────────────────────────────────────────────

  test "parses apple music album URL" do
    result = EmbedParser.parse("https://music.apple.com/us/album/folklore/1528112358")
    assert_equal :apple_music, result.provider
    assert_includes result.embed_url, "embed.music.apple.com"
    assert_equal 450, result.height
  end

  test "parses apple music playlist URL" do
    result = EmbedParser.parse("https://music.apple.com/us/playlist/my-playlist/pl.abc123")
    assert_equal :apple_music, result.provider
    assert_includes result.embed_url, "embed.music.apple.com"
  end

  # ── title_hint ───────────────────────────────────────────────────────────────

  test "each provider returns a non-blank title_hint" do
    urls = [
      "https://youtu.be/dQw4w9WgXcQ",
      "https://vimeo.com/76979871",
      "https://open.spotify.com/track/abc",
      "https://soundcloud.com/a/b",
      "https://music.apple.com/us/album/x/1"
    ]
    urls.each do |url|
      result = EmbedParser.parse(url)
      assert result&.title_hint&.present?, "Expected title_hint for #{url}"
    end
  end
end
