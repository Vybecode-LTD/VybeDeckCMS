module EmbedHelper
  # Returns an EmbedParser::Result, or nil if the URL is not recognised.
  def embed_for(url)
    EmbedParser.parse(url)
  end
end
