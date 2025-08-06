# frozen_string_literal: true

require_relative "azul/configuration"
require_relative "azul/errors"
require_relative "azul/url_builder"
require_relative "azul/http_client"
require_relative "azul/request"
require_relative "azul/response"
require_relative "azul/resources/base"
require_relative "azul/resources/payment"
require_relative "azul/resources/refund"
require_relative "azul/resources/transaction"
require_relative "azul/version"

module Azul
  class << self
    attr_accessor :configuration

    def configure
      @configuration ||= Configuration.new
      yield(@configuration)
    end
  end

  # Aliasing the resource classes at the module level
  Base = Resources::Base
  Payment = Resources::Payment
  Refund = Resources::Refund
  Transaction = Resources::Transaction
end
