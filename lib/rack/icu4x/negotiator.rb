# frozen_string_literal: true

module Rack
  module ICU4X
    # Performs sophisticated language negotiation using ICU4X's maximize/minimize.
    #
    # Supports three strategies:
    # - :filtering - Match as many available locales as possible in preference order
    # - :matching  - Find the best match for each requested locale (unique results)
    # - :lookup    - Find a single best locale (with required default)
    #
    # @example
    #   negotiator = Rack::ICU4X::Negotiator.new(%w[en-US en-GB ja], strategy: :filtering)
    #   negotiator.negotiate(%w[en-AU ja-JP])  # => ["en-US", "ja"]
    class Negotiator
      STRATEGIES = %i[filtering matching lookup].freeze
      public_constant :STRATEGIES

      # @param available_locales [Array<String>] List of available locale identifiers
      # @param strategy [Symbol] Negotiation strategy (:filtering, :matching, :lookup)
      # @param default_locale [String, nil] Default locale for :lookup strategy
      def initialize(available_locales, strategy: :filtering, default_locale: nil)
        validate_strategy!(strategy)
        validate_default_locale!(strategy, default_locale)

        @strategy = strategy
        @default_locale = default_locale
        @available = build_available_index(available_locales)
      end

      # Negotiate locales based on the configured strategy.
      #
      # @param requested_locales [Array<String>] Requested locale identifiers in preference order
      # @return [Array<String>] Matched locale identifiers
      def negotiate(requested_locales)
        case @strategy
        when :filtering then filter_matches(requested_locales)
        when :matching then match_best(requested_locales)
        when :lookup then lookup_single(requested_locales)
        else raise ArgumentError, "Unknown strategy: #{@strategy}"
        end
      end

      private def validate_strategy!(strategy)
        return if STRATEGIES.include?(strategy)

        raise ArgumentError, "Invalid strategy: #{strategy}. Must be one of: #{STRATEGIES.join(", ")}"
      end

      private def validate_default_locale!(strategy, default_locale)
        return unless strategy == :lookup && default_locale.nil?

        raise ArgumentError, "default_locale is required for :lookup strategy"
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

      private def filter_matches(requested_locales)
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

      private def match_best(requested_locales)
        requested_locales.filter_map {|req_str|
          req_max = maximize_locale(req_str)
          find_exact_match(@available, req_max)&.dig(:original) ||
            find_lang_script_match(@available, req_max)&.dig(:original)
        }.uniq
      end

      private def lookup_single(requested_locales)
        result = match_best(requested_locales).first
        result ? [result] : [@default_locale].compact
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
