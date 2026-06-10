module VybeDeck
  module Plugin
    # Raised when a plugin violates its declared sandbox restrictions.
    class SandboxViolation < StandardError; end
  end
end
