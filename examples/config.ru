# frozen_string_literal: true

require_relative "app"

use Rack::ICU4X::Locale, available_locales: %w[en ja de fr], cookie: "locale"

run DemoApp
