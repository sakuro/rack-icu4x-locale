# frozen_string_literal: true

require_relative "app"

use Rack::ICU4X::Locale,
  from: %w[en ja de fr],
  detectors: [{query: "lang"}, {cookie: "locale"}, :header],
  default: "en"

run DemoApp
