# frozen_string_literal: true

module Rack
  module ICU4X
    # Performs script-safe language negotiation using ICU4X's maximize.
    #
    # Matches requested locales against available locales, respecting script differences
    # to avoid politically sensitive fallbacks (e.g., zh-TW won't match zh-CN).
    #
    # @example
    #   negotiator = Rack::ICU4X::Negotiator.new(%w[en-US en-GB ja])
    #   negotiator.negotiate(%w[en-AU ja-JP])  # => ["en-US", "ja"]
    class Negotiator
      # @param available_locales [Array<String, ICU4X::Locale>] List of available locales
      def initialize(available_locales)
        @available = build_available_index(available_locales)
      end

      # Negotiate locales, returning all matches in preference order.
      #
      # @param requested_locales [Array<String>] Requested locale identifiers in preference order
      # @return [Array<String>] Matched locale identifiers
      def negotiate(requested_locales)
        matched = []
        remaining = @available.dup

        requested_locales.each do |req_str|
          req_max = maximize_locale(req_str)

          # 1. Exact match (language + script + region)
          if (found = find_exact_match(remaining, req_max))
            matched << found[:original]
            remaining.delete(found)
            next
          end

          # 2. Language + Script match (ignore region)
          #    CRITICAL: Script MUST match to avoid politically sensitive fallbacks
          if (found = find_lang_script_match(remaining, req_max))
            matched << found[:original]
            remaining.delete(found)
          end
        end

        matched
      end

      private def build_available_index(locales)
        locales.map do |locale_or_str|
          locale = locale_or_str.is_a?(::ICU4X::Locale) ? locale_or_str : ::ICU4X::Locale.parse(locale_or_str)
          maximized = locale.maximize
          {
            original: locale.to_s,
            locale:,
            maximized:,
            language: maximized.language,
            script: maximized.script,
            region: maximized.region
          }
        end
      end

      private def maximize_locale(locale_str) = ::ICU4X::Locale.parse(locale_str).maximize

      private def find_exact_match(candidates, req_max)
        candidates.find do |entry|
          entry[:language] == req_max.language &&
            entry[:script] == req_max.script &&
            entry[:region] == req_max.region
        end
      end

      private def find_lang_script_match(candidates, req_max)
        candidates.find do |entry|
          entry[:language] == req_max.language &&
            entry[:script] == req_max.script
        end
      end
    end
  end
end
