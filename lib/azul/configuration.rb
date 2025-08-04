# frozen_string_literal: true

module Azul
  class Configuration
    attr_writer :merchant_id, :environment, :auth_1, :auth_2, :client_certificate, :client_key
    attr_accessor :timeout, :client_certificate_path, :client_key_path

    def initialize
      @merchant_id = nil
      @environment = nil
      @auth_1 = nil
      @auth_2 = nil
      @client_certificate = nil
      @client_key = nil
      @client_certificate_path = nil
      @client_key_path = nil
      @timeout = 120
    end

    def merchant_id
      return @merchant_id if @merchant_id

      error_message = "Azul merchant id es requerido!"
      raise ConfigurationError, error_message
    end

    def environment
      if [:production, :development].include?(@environment&.to_sym)
        @environment&.to_sym
      else
        error_message = "Azul environment (:production or :development) es requerido!"
        raise ConfigurationError, error_message
      end
    end

    def auth_1
      return @auth_1 if @auth_1

      error_message = "Azul Auth1 es requerido!"
      raise ConfigurationError, error_message
    end

    def auth_2
      return @auth_2 if @auth_2

      error_message = "Azul Auth2 es requerido!"
      raise ConfigurationError, error_message
    end

    def client_certificate
      if @client_certificate_path && File.exist?(@client_certificate_path)
        File.read(@client_certificate_path)
      elsif @client_certificate
        @client_certificate
      else
        error_message = "Azul client certificate es requerido para autenticación mTLS!"
        raise ConfigurationError, error_message
      end
    end

    def client_key
      if @client_key_path && File.exist?(@client_key_path)
        File.read(@client_key_path)
      elsif @client_key
        @client_key
      else
        error_message = "Azul client key es requerido para autenticación mTLS!"
        raise ConfigurationError, error_message
      end
    end
  end
end
