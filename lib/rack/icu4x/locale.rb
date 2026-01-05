# frozen_string_literal: true

require "zeitwerk"
require_relative "locale/version"

module Rack
  module Icu4x
    # Rack::Icu4x::Locale provides [description of your gem].
    #
    # This module serves as the namespace for the gem's functionality.
    module Locale
      class Error < StandardError; end

      loader = Zeitwerk::Loader.for_gem
      loader.ignore("#{__dir__}/locale/version.rb")
      # loader.inflector.inflect(
      #   "html" => "HTML",
      #   "ssl" => "SSL"
      # )
      loader.setup
    end
  end
end
