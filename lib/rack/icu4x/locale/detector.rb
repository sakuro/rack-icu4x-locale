# frozen_string_literal: true

module Rack
  module ICU4X
    class Locale
      # Factory module for building detector instances from various specification formats.
      #
      # Detectors are responsible for extracting locale preferences from the Rack environment.
      # All detectors respond to `#call(env)` and return:
      # - String: single locale (e.g., "ja")
      # - Array<String>: multiple locales in preference order (e.g., ["ja", "en"])
      # - nil: no locale detected
      #
      # @example Building detectors from different specification formats
      #   Detector.build(:header)                    # => Detector::Header.new
      #   Detector.build({ cookie: "locale" })       # => Detector::Cookie.new("locale")
      #   Detector.build(->(env) { "ja" })           # => the Proc itself
      module Detector
        class InvalidSpecificationError < Error; end

        INFLECTOR = Zeitwerk::Inflector.new
        private_constant :INFLECTOR

        # Build a detector from various specification formats.
        #
        # @param spec [Symbol, Hash, Proc, #call] Detector specification
        # @return [#call] Detector instance responding to #call(env)
        # @raise [InvalidSpecificationError] if the specification is invalid
        def self.build(spec)
          case spec
          when Symbol then build_from_symbol(spec)
          when Hash then build_from_hash(spec)
          when Proc then spec
          else
            validate_callable!(spec)
            spec
          end
        end

        private_class_method def self.build_from_symbol(symbol)
          class_name = INFLECTOR.camelize(symbol.to_s, nil)
          const_get(class_name).new
        rescue NameError
          raise InvalidSpecificationError, "Unknown detector: #{symbol.inspect}"
        end

        private_class_method def self.build_from_hash(hash)
          raise InvalidSpecificationError, "Hash must have exactly one key" unless hash.size == 1

          key, value = hash.first
          class_name = INFLECTOR.camelize(key.to_s, nil)
          const_get(class_name).new(value)
        rescue NameError
          raise InvalidSpecificationError, "Unknown detector type: #{key.inspect}"
        end

        private_class_method def self.validate_callable!(obj)
          return if obj.respond_to?(:call)

          raise InvalidSpecificationError, "Detector must respond to #call: #{obj.inspect}"
        end
      end
    end
  end
end
