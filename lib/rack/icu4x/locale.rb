# frozen_string_literal: true

require "icu4x"
require "rack"
require "zeitwerk"
require_relative "locale/version"
require_relative "negotiator"

module Rack
  module ICU4X
    # Rack middleware that detects user's preferred locales from Accept-Language header and cookies.
    #
    # Uses ICU4X's maximize/minimize for sophisticated language negotiation that respects
    # script boundaries (e.g., zh-TW/Hant will NOT match zh-CN/Hans).
    #
    # @example Basic usage
    #   use Rack::ICU4X::Locale, available_locales: %w[en ja]
    #
    # @example With cookie support
    #   use Rack::ICU4X::Locale, available_locales: %w[en ja], cookie: "locale"
    #
    # @example With negotiation strategy
    #   use Rack::ICU4X::Locale,
    #     available_locales: %w[en-US en-GB ja],
    #     strategy: :filtering,
    #     default_locale: "en-US"
    class Locale
      ENV_KEY = "rack.icu4x.locale"
      public_constant :ENV_KEY

      class Error < StandardError; end

      # @param app [#call] The Rack application
      # @param available_locales [Array<String>] List of available locale identifiers
      # @param cookie [String, nil] Cookie name for locale preference (optional)
      # @param strategy [Symbol] Negotiation strategy (:filtering, :matching, :lookup)
      # @param default_locale [String, nil] Default locale (required for :lookup strategy)
      def initialize(app, available_locales:, cookie: nil, strategy: :filtering, default_locale: nil)
        @app = app
        @available_locales = available_locales
        @cookie_name = cookie
        @default_locale = default_locale
        @negotiator = Negotiator.new(available_locales, strategy:, default_locale:)
      end

      # @param env [Hash] Rack environment
      # @return [Array] Response from the wrapped application
      def call(env)
        env[ENV_KEY] = detect_locales(env)
        @app.call(env)
      end

      private def detect_locales(env)
        locales = cookie_locale(env) || accept_language_locales(env)
        locales.empty? ? default_locales : locales
      end

      private def cookie_locale(env)
        return nil unless @cookie_name

        cookies = ::Rack::Utils.parse_cookies(env)
        locale = cookies[@cookie_name]
        return nil unless locale

        # Use negotiator for script-safe matching
        matched = @negotiator.negotiate([locale])
        return nil if matched.empty?

        matched.map {|l| ::ICU4X::Locale.parse(l) }
      end

      private def accept_language_locales(env)
        header = env["HTTP_ACCEPT_LANGUAGE"]
        return [] if header.nil?

        requested = parse_accept_language(header)
        matched = @negotiator.negotiate(requested)
        matched.map {|l| ::ICU4X::Locale.parse(l) }
      end

      private def parse_accept_language(header)
        header.split(",")
          .map {|part| parse_entry(part) }
          .sort_by {|_, q| -q }
          .map(&:first)
      end

      private def parse_entry(part)
        locale, quality = part.strip.split(";q=")
        [locale.strip, Float(quality || "1")]
      end

      private def default_locales
        return [] if @default_locale.nil?

        [::ICU4X::Locale.parse(@default_locale)]
      end

      loader = Zeitwerk::Loader.for_gem
      loader.inflector.inflect("icu4x" => "ICU4X")
      loader.ignore("#{__dir__}/locale/version.rb")
      loader.ignore("#{__dir__}/negotiator.rb")
      loader.setup
    end
  end
end
