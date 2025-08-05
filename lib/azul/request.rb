# frozen_string_literal: true

module Azul
  class Request
    attr_reader :method, :api_url, :headers, :params, :payment_method_metadata

    def initialize(method, api_url, headers, params)
      @method = method
      @api_url = api_url
      @headers = headers

      # Extract payment method details before filtering
      @payment_method_metadata = extract_payment_metadata(params)

      @params = filter_sensitive_params(params)
    end

    private

    def extract_payment_metadata(params)
      return {} if params["CardNumber"].blank?

      clean_number = params["CardNumber"].to_s.gsub(/\D/, "")

      {
        last4: clean_number[-4..],
        brand: identify_card_brand(clean_number),
        exp_month: extract_exp_month(params["Expiration"]),
        exp_year: extract_exp_year(params["Expiration"])
      }
    end

    def identify_card_brand(card_number)
      case card_number
      when /^4/
        "Visa"
      when /^5[1-5]/, /^222[1-9]/, /^22[3-9]/, /^2[3-6]/, /^27[0-1]/, /^2720/
        "Mastercard"
      when /^3[47]/
        "American Express"
      when /^6011/, /^622126/, /^62212[7-9]/, /^6221[3-9]/, /^622[2-8]/, /^6229[0-1]/, /^62292[0-5]/, /^64[4-9]/, /^65/
        "Discover"
      end
    end

    def extract_exp_month(expiration)
      return if expiration.blank?

      # Format: YYYYMM
      expiration.to_s[-2..]
    end

    def extract_exp_year(expiration)
      return if expiration.blank?

      # Format: YYYYMM
      expiration.to_s[0..3]
    end

    def filter_sensitive_params(params)
      return params unless params.is_a?(Hash)

      params.each do |key, value|
        case key
        when "CardNumber"
          params[key] = mask_card_number(value) if value.present?
        when "Expiration", "CVC"
          params[key] = "[FILTERED]" if value.present?
        end
      end

      params
    end

    def mask_card_number(card_number)
      return card_number unless card_number.is_a?(String) && card_number.length >= 8

      first_four = card_number[0..3]
      last_four = card_number[-4..]
      masked_middle = "*" * (card_number.length - 8)

      "#{first_four}#{masked_middle}#{last_four}"
    end
  end
end
