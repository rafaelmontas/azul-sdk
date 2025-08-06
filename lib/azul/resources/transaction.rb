# frozen_string_literal: true

module Azul
  module Resources
    class Transaction < Base
      def self.search(params = {})
        new(params).create(action: :search)
      end

      def self.verify(params = {})
        new(params).create(action: :verify)
      end
    end
  end
end
