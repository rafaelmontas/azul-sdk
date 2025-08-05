# frozen_string_literal: true

module Azul
  class Response
    attr_reader :raw_response, :request

    def initialize(raw_response, request)
      @raw_response = raw_response
      @request = request
    end

    def success?
      http_success? && azul_success?
    end

    def body
      @body ||= parse_body
    end

    def iso_code
      body["IsoCode"]
    end

    def response_code
      body["ResponseCode"]
    end

    def response_message
      body["ResponseMessage"]
    end

    def error_description
      body["ErrorDescription"]
    end

    def authorization_code
      body["AuthorizationCode"]
    end

    def azul_order_id
      body["AzulOrderId"]
    end

    def country_code
      body["CountryCode"]
    end

    def custom_order_id
      body["CustomOrderId"]
    end

    def date_time
      body["DateTime"]
    end

    def lot_number
      body["LotNumber"]
    end

    def rrn
      body["RRN"]
    end

    def ticket
      body["Ticket"]
    end

    def threeds_method
      body["ThreeDSMethod"]
    end

    def threeds_challenge
      body["ThreeDSChallenge"]
    end

    # Token related methods
    def data_vault_token
      body["DataVaultToken"]
    end

    def data_vault_expiration
      body["DataVaultExpiration"]
    end

    def data_vault_brand
      body["DataVaultBrand"]
    end

    # Payment method details from request metadata
    def payment_method_details
      @request.payment_method_metadata
    end

    def http_success?
      @raw_response.is_a?(Net::HTTPSuccess)
    end

    def azul_success?
      ["00", "3D2METHOD", "3D"].include?(iso_code) || response_message == "APROBADA" || response_code == "SEARCHED"
    end

    def parse_body
      return {} if raw_response.body.blank?

      JSON.parse(raw_response.body)
    end
  end
end
