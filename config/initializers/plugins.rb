require "vybedeck/plugin/registry"
require "vybedeck/plugin/base"

# Load all plugin files from lib/plugins/.
Dir[Rails.root.join("lib/plugins/**/*.rb")].sort.each { |f| require f }
