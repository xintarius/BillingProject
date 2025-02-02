ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # set up gems listed in the Gemfile
require "bootsnap/setup" # Speed up boot time by caching expensive operations