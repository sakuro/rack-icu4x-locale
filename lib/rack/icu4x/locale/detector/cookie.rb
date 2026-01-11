# frozen_string_literal: true

module Rack
  module ICU4X
    class Locale
      module Detector
        # Detects locale from a cookie value.
        #
        # @example With default cookie name
        #   detector = Cookie.new
        #   env = { "HTTP_COOKIE" => "locale=ja" }
        #   detector.call(env) # => "ja"
        #
        # @example With custom cookie name
        #   detector = Cookie.new("user_locale")
        #   env = { "HTTP_COOKIE" => "user_locale=en" }
        #   detector.call(env) # => "en"
        class Cookie
          DEFAULT_NAME = "locale"
          private_constant :DEFAULT_NAME

          # @param name [String] Cookie name to read locale from
          def initialize(name=DEFAULT_NAME)
            @name = name
          end

          # @param env [Hash] Rack environment
          # @return [String, nil] Locale from cookie, or nil if not present
          def call(env)
            cookies = ::Rack::Utils.parse_cookies(env)
            locale = cookies[@name]
            return nil if locale.nil? || locale.empty?

            locale
          end

          private

          attr_reader :name
        end
      end
    end
  end
end
