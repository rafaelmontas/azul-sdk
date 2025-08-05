# frozen_string_literal: true

module Azul
  class UrlBuilder
    ENDPOINTS = {
      development: "https://pruebas.azul.com.do/WebServices/JSON/Default.aspx",
      production: "https://pagos.azul.com.do/WebServices/JSON/Default.aspx"
    }.freeze

    ACTIONS = {
      post: "ProcessPost",
      void: "ProcessVoid",
      verify: "VerifyPayment",
      search: "SearchPayments",
      process_threeds_method: "processthreedsmethod",
      process_threeds_challenge: "processthreedschallenge"
    }.freeze

    def initialize(environment)
      @environment = environment
    end

    def build(action: nil)
      base_url = ENDPOINTS[@environment]

      return base_url unless action

      uri = URI(base_url)
      query_param = ACTIONS[action]

      uri.query = query_param if query_param

      uri.to_s
    end
  end
end
