# frozen_string_literal: true

module Azul
  module Resources
    class Payment < Base
      def self.sale(params = {})
        new(params.merge(trx_type: "Sale")).create
      end

      def self.hold(params = {})
        new(params.merge(trx_type: "Hold", acquirer_ref_data: "1")).create
      end

      def self.capture(params = {})
        new(params).create(action: :post)
      end

      def self.void(params = {})
        new(params).create(action: :void)
      end

      def self.process_threeds_method(params = {})
        new(params).create(action: :process_threeds_method)
      end

      def self.process_threeds_challenge(params = {})
        new(params).create(action: :process_threeds_challenge)
      end
    end
  end
end
