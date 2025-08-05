# frozen_string_literal: true

require_relative "azul/configuration"
require_relative "azul/errors"
require_relative "azul/url_builder"
require_relative "azul/http_client"
require_relative "azul/request"
require_relative "azul/response"
require_relative "azul/version"

module Azul
  class << self
    attr_accessor :configuration

    def configure
      @configuration ||= Configuration.new
      yield(@configuration)
    end
  end
end
