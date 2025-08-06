# frozen_string_literal: true

module Azul
  module Errors
    class ConfigurationError < StandardError; end

    class ApiError < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
        super(build_error_message(response))
      end

      private

      def build_error_message(response)
        "Azul API Error: #{response.error_description} - #{response.response_message}"
      end
    end

    class DeclineError < ApiError; end
    class ProcessingError < ApiError; end
    class AuthenticationError < ApiError; end

    class Error < StandardError
      DECLINE_CODES = %w[03 04 05 07 12 13 14 41 43 46 51 54 57 59 61 62 63 82 83 91].freeze
      PROCESSING_CODES = %w[99].freeze
      AUTH_CODES = %w[08 3D].freeze

      def self.from_response(response)
        case response.iso_code
        when *DECLINE_CODES
          DeclineError.new(response)
        when *PROCESSING_CODES
          ProcessingError.new(response)
        when *AUTH_CODES
          AuthenticationError.new(response)
        else
          ApiError.new(response)
        end
      end
    end
  end

  ConfigurationError = Errors::ConfigurationError
  ApiError = Errors::ApiError
  DeclineError = Errors::DeclineError
  ProcessingError = Errors::ProcessingError
  AuthenticationError = Errors::AuthenticationError
  Error = Errors::Error
end
