# frozen_string_literal: true

module Azul
  module Resources
    class Base
      attr_reader :params, :response

      PARAM_MAPPING = {
        card_number: "CardNumber",
        expiration: "Expiration",
        cvc: "CVC",
        amount: "Amount",
        itbis: "Itbis",
        trx_type: "TrxType",
        order_number: "OrderNumber",
        customer_service_phone: "CustomerServicePhone",
        ecommerce_url: "ECommerceURL",
        custom_order_id: "CustomOrderId",
        alt_merchant_name: "AltMerchantName",
        apple_pay: "ApplePay",
        payment_token: "PaymentToken",
        cryptogram: "Cryptogram",
        eci_indicator: "ECIIndicator",
        google_pay: "GooglePay",
        data_vault_token: "DataVaultToken",
        save_to_data_vault: "SaveToDataVault",
        force_no_3ds: "ForceNo3DS",
        three_ds_auth: "ThreeDSAuth",
        term_url: "TermUrl", # Nested in three_ds_auth
        method_notification_url: "MethodNotificationUrl", # Nested in three_ds_auth
        requestor_challenge_indicator: "RequestorChallengeIndicator", # Nested in three_ds_auth
        card_holder_info: "CardHolderInfo",
        name: "Name", # Nested in card_holder_info
        email: "Email", # Nested in card_holder_info
        phone_mobile: "PhoneMobile", # Nested in card_holder_info
        browser_info: "BrowserInfo",
        accept_header: "AcceptHeader", # Nested in browser_info
        ip_address: "IPAddress", # Nested in browser_info
        user_agent: "UserAgent", # Nested in browser_info
        language: "Language", # Nested in browser_info
        color_depth: "ColorDepth", # Nested in browser_info
        screen_width: "ScreenWidth", # Nested in browser_info
        screen_height: "ScreenHeight", # Nested in browser_info
        time_zone: "TimeZone", # Nested in browser_info
        javascript_enable: "JavaScriptEnable", # Nested in browser_info
        method_notification_status: "MethodNotificationStatus",
        cres: "CRes",
        original_date: "OriginalDate",
        original_trx_ticket_nr: "OriginalTrxTicketNr",
        azul_order_id: "AzulOrderId",
        response_code: "ResponseCode",
        rrn: "RRN",
        date_from: "DateFrom",
        date_to: "DateTo",
        acquirer_ref_data: "AcquirerRefData"
      }.freeze

      def initialize(params = {})
        @params = params
      end

      def create(action: nil)
        @http_client ||= HttpClient.new
        @response = @http_client.post(request_params, action: action)

        if @response.success?
          @response
        else
          error = Error.from_response(@response)
          raise error
        end
      end

      private

      def request_params
        mapped = map_parameters_to_api_format

        # If data_vault_token is present, add empty card_number and expiration
        if params[:data_vault_token] || params["data_vault_token"]
          mapped["CardNumber"] ||= ""
          mapped["Expiration"] ||= ""
        end

        mapped
      end

      def map_parameters_to_api_format
        params.each_with_object({}) do |(key, value), result|
          api_param = PARAM_MAPPING[key.to_sym] || to_pascal_case(key.to_s)
          result[api_param] = value.is_a?(Hash) ? process_nested_params(value) : value
        end
      end

      def process_nested_params(hash)
        result = {}

        hash.each do |key, value|
          api_param = PARAM_MAPPING[key.to_sym] || to_pascal_case(key.to_s)

          result[api_param] = value.is_a?(Hash) ? process_nested_params(value) : value
        end

        result
      end

      def to_pascal_case(string)
        string.split("_").map(&:capitalize).join
      end
    end
  end
end
