# frozen_string_literal: true

module Rack
  module ICU4X
    class Locale
      module Detector
        # Detects locale from a query string parameter.
        #
        # @example With default parameter name
        #   detector = Query.new
        #   env = Rack::MockRequest.env_for("/?locale=ja")
        #   detector.call(env) # => "ja"
        #
        # @example With custom parameter name
        #   detector = Query.new("lang")
        #   env = Rack::MockRequest.env_for("/?lang=en")
        #   detector.call(env) # => "en"
        class Query
          DEFAULT_PARAM = "locale"
          private_constant :DEFAULT_PARAM

          # @param param [String] Query parameter name to read locale from
          def initialize(param=DEFAULT_PARAM)
            @param = param
          end

          # @param env [Hash] Rack environment
          # @return [String, nil] Locale from query parameter, or nil if not present
          def call(env)
            query_string = env["QUERY_STRING"]
            return nil if query_string.nil? || query_string.empty?

            params = ::Rack::Utils.parse_query(query_string)
            locale = params[@param]
            return nil if locale.nil? || locale.empty?

            locale
          end

          private attr_reader :param
        end
      end
    end
  end
end
