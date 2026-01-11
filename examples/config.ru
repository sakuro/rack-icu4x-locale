# frozen_string_literal: true

require_relative "app"

use Rack::ICU4X::Locale, from: %w[en ja de fr], cookie: "locale", default: "en"

run DemoApp
