require "uri"
require "cgi"

# Parses a user-supplied URL into an embeddable iframe source.
# Returns an EmbedParser::Result struct or nil if the URL is unrecognised.
#
# Usage:
#   result = EmbedParser.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
#   result.provider   # => :youtube
#   result.embed_url  # => "https://www.youtube.com/embed/dQw4w9WgXcQ?rel=0"
#   result.aspect     # => "16 / 9"
#   result.height     # => nil (use aspect-ratio instead)
class EmbedParser
  Result = Struct.new(:provider, :embed_url, :aspect, :height, :title_hint, keyword_init: true)

  # Public entry point — returns Result or nil.
  def self.parse(url)
    return nil if url.blank?
    new(url.to_s.strip).call
  end

  def initialize(url)
    @url = url
    @uri = URI.parse(url) rescue nil
  end

  def call
    return nil unless @uri&.host
    [
      method(:youtube),
      method(:vimeo),
      method(:spotify),
      method(:soundcloud),
      method(:apple_music)
    ].each do |parser|
      result = parser.call
      return result if result
    end
    nil
  end

  private

  # ── YouTube ──────────────────────────────────────────────────────────────────
  # Handles:
  #   https://www.youtube.com/watch?v=ID
  #   https://youtu.be/ID
  #   https://www.youtube.com/playlist?list=LIST_ID

  def youtube
    host = bare_host
    return nil unless host == "youtube.com" || host == "youtu.be"

    if host == "youtu.be"
      vid = @uri.path.delete_prefix("/").split("?").first
      return nil if vid.blank?
      return video16x9(:youtube, "https://www.youtube.com/embed/#{vid}?rel=0", "YouTube video")
    end

    params = decode_query
    if @uri.path == "/watch" && (vid = params["v"])
      return video16x9(:youtube, "https://www.youtube.com/embed/#{vid}?rel=0", "YouTube video")
    end

    if @uri.path == "/playlist" && (list = params["list"])
      return video16x9(:youtube, "https://www.youtube.com/embed/videoseries?list=#{list}&rel=0", "YouTube playlist")
    end

    nil
  end

  # ── Vimeo ────────────────────────────────────────────────────────────────────
  # https://vimeo.com/ID  or  https://vimeo.com/CHANNEL/ID

  def vimeo
    return nil unless bare_host == "vimeo.com"
    vid = @uri.path.split("/").find { |s| s.match?(/\A\d+\z/) }
    return nil if vid.blank?
    video16x9(:vimeo, "https://player.vimeo.com/video/#{vid}", "Vimeo video")
  end

  # ── Spotify ──────────────────────────────────────────────────────────────────
  # https://open.spotify.com/TYPE/ID
  # Type: track, album, playlist, artist, episode, show

  def spotify
    return nil unless @uri.host == "open.spotify.com"
    parts = @uri.path.split("/").reject(&:blank?)
    type, id = parts[0], parts[1]
    return nil unless type && id
    return nil unless %w[track album playlist artist episode show].include?(type)

    height = type.in?(%w[track episode]) ? 152 : 352
    Result.new(
      provider:   :spotify,
      embed_url:  "https://open.spotify.com/embed/#{type}/#{id}?utm_source=oembed",
      aspect:     nil,
      height:     height,
      title_hint: "Spotify #{type}"
    )
  end

  # ── SoundCloud ───────────────────────────────────────────────────────────────
  # https://soundcloud.com/ARTIST/TRACK  (or sets, profiles, etc.)

  def soundcloud
    return nil unless bare_host == "soundcloud.com"
    encoded  = CGI.escape(@url)
    embed_url = "https://w.soundcloud.com/player/?url=#{encoded}" \
                "&auto_play=false&hide_related=true" \
                "&show_comments=false&show_user=true" \
                "&show_reposts=false&visual=false"
    Result.new(
      provider:   :soundcloud,
      embed_url:  embed_url,
      aspect:     nil,
      height:     166,
      title_hint: "SoundCloud"
    )
  end

  # ── Apple Music ──────────────────────────────────────────────────────────────
  # https://music.apple.com/us/album/NAME/ID
  # Embed by replacing host with embed.music.apple.com

  def apple_music
    return nil unless @uri.host == "music.apple.com"
    embed_url = @url.sub("music.apple.com", "embed.music.apple.com")
    Result.new(
      provider:   :apple_music,
      embed_url:  embed_url,
      aspect:     nil,
      height:     450,
      title_hint: "Apple Music"
    )
  end

  # ── helpers ──────────────────────────────────────────────────────────────────

  def bare_host
    @uri.host.to_s.downcase.delete_prefix("www.")
  end

  def decode_query
    URI.decode_www_form(@uri.query.to_s).to_h
  end

  def video16x9(provider, embed_url, title)
    Result.new(provider: provider, embed_url: embed_url, aspect: "16 / 9", height: nil, title_hint: title)
  end
end
