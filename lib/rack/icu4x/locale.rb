# frozen_string_literal: true

require "icu4x"
require "rack"
require "zeitwerk"
require_relative "locale/version"

module Rack
  module ICU4X
    # Rack middleware that detects user's preferred locales from various sources.
    #
    # Uses ICU4X's maximize for script-safe language negotiation that respects
    # script boundaries (e.g., zh-TW/Hant will NOT match zh-CN/Hans).
    #
    # @example Basic usage (Accept-Language header only)
    #   use Rack::ICU4X::Locale, from: %w[en ja]
    #
    # @example With multiple detectors
    #   use Rack::ICU4X::Locale,
    #     from: %w[en ja],
    #     detectors: [{ query: "lang" }, { cookie: "locale" }, :header]
    #
    # @example With custom detector
    #   use Rack::ICU4X::Locale,
    #     from: %w[en ja],
    #     detectors: [->(env) { env["rack.session"]&.[]("locale") }, :header]
    class Locale
      Zeitwerk::Loader.new.tap do |loader|
        loader.push_dir("#{__dir__}/locale", namespace: Rack::ICU4X::Locale)
        loader.ignore("#{__dir__}/locale/version.rb")
        loader.setup
      end

      ENV_KEY = "rack.icu4x.locale"
      public_constant :ENV_KEY

      DEFAULT_DETECTORS = [:header].freeze
      public_constant :DEFAULT_DETECTORS

      class Error < StandardError; end

      # @param app [#call] The Rack application
      # @param from [Array<String, ICU4X::Locale>] List of available locales
      # @param detectors [Array] Detector specifications (optional, default: [:header])
      # @param default [String, ICU4X::Locale, nil] Default locale when no match is found (optional)
      def initialize(app, from:, detectors: DEFAULT_DETECTORS, default: nil)
        @app = app
        @from = from.map {|locale| normalize_locale(locale) }
        @detectors = build_detectors(detectors)
        @default = default && normalize_locale(default)
        validate_default_in_from!
        @negotiator = Negotiator.new(@from)
      end

      # @param env [Hash] Rack environment
      # @return [Array] Response from the wrapped application
      def call(env)
        env[ENV_KEY] = detect_locales(env)
        @app.call(env)
      end

      private def validate_default_in_from!
        return unless @default
        return if @from.include?(@default)

        raise Error, "default #{@default.to_s.inspect} is not in available locales"
      end

      private def build_detectors(specs)
        effective_specs = specs.empty? ? DEFAULT_DETECTORS : specs
        effective_specs.map {|spec| Detector.build(spec) }
      end

      private def detect_locales(env)
        result = try_detectors(env)
        result.empty? && @default ? [@default] : result
      end

      private def try_detectors(env)
        @detectors.each do |detector|
          raw = detector.call(env)
          next if raw.nil?

          requested = Array(raw)
          matched = @negotiator.negotiate(requested) {|invalid_locale|
            log_invalid_locale(env, invalid_locale)
          }
          return matched.map {|locale| ::ICU4X::Locale.parse(locale) } unless matched.empty?
        end
        []
      end

      private def normalize_locale(locale) = locale.is_a?(::ICU4X::Locale) ? locale : ::ICU4X::Locale.parse(locale)

      private def log_invalid_locale(env, locale)
        message = "Ignored invalid locale: #{locale}"
        if env["rack.logger"]
          env["rack.logger"].warn(message)
        else
          env["rack.errors"]&.puts(message)
        end
      end
    end
  end
end
