# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in spout.gemspec.
gemspec

group :test do
  gem "artifice"
  gem "minitest"
  gem "rake"
  gem "simplecov", "~> 0.16.1", require: false
end
