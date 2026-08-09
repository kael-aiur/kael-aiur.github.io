# frozen_string_literal: true

source "https://rubygems.org"

# All registered theme profiles are installed so switching `_config.yml` is
# the only dependency-selection step required by local and CI builds.
gem "jekyll-theme-chirpy", "~> 7.6"
gem "minima", "~> 2.5"
gem "html-proofer", "~> 5.0", group: :test

platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.2.0", platforms: [:windows]
