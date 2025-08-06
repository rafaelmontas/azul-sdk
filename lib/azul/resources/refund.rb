# frozen_string_literal: true

module Azul
  module Resources
    class Refund < Base
      def self.create(params = {})
        new(params.merge(trx_type: "Refund")).create
      end
    end
  end
end
