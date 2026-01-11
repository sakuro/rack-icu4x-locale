# frozen_string_literal: true

module Rack
  module ICU4X
    class Locale
      module Detector
        # Detects locales from the Accept-Language HTTP header.
        #
        # Returns locales sorted by quality value in descending order.
        #
        # @example
        #   detector = Header.new
        #   env = { "HTTP_ACCEPT_LANGUAGE" => "ja,en;q=0.9,de;q=0.8" }
        #   detector.call(env) # => ["ja", "en", "de"]
        class Header
          # @param env [Hash] Rack environment
          # @return [Array<String>, nil] Locales sorted by quality value, or nil if header is missing
          def call(env)
            header = env["HTTP_ACCEPT_LANGUAGE"]
            return nil if header.nil? || header.empty?

            parse_accept_language(header)
          end

          private def parse_accept_language(header)
            header.split(",")
              .map {|part| parse_entry(part) }
              .sort_by {|_, quality| -quality }
              .map(&:first)
          end

          private def parse_entry(part)
            locale, quality = part.strip.split(";q=")
            [locale.strip, Float(quality || "1")]
          end
        end
      end
    end
  end
end
