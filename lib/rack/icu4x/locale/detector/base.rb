# frozen_string_literal: true

module Rack
  module ICU4X
    class Locale
      module Detector
        # Common interface for all detector classes.
        #
        # All detectors respond to `#call(env)` and return:
        # - String: single locale (e.g., "ja")
        # - Array<String>: multiple locales in preference order (e.g., ["ja", "en"])
        # - nil: no locale detected
        module Base
          # Detect locale(s) from the Rack environment.
          #
          # @param env [Hash] Rack environment
          # @return [String, Array<String>, nil] Detected locale(s) or nil
          def call(env)
            raise NotImplementedError, "#{self.class}#call must be implemented"
          end
        end
      end
    end
  end
end
