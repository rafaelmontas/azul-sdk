# frozen_string_literal: true

module Azul
  module Errors
    class Error < StandardError; end
    class ConfigurationError < Error; end
  end

  Error = Errors::Error
  ConfigurationError = Errors::ConfigurationError
end
