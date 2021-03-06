# frozen_string_literal: true

module BusinessCentral
  class Client
    extend BusinessCentral::Object::ObjectHelper

    DEFAULT_LOGIN_URL = 'https://login.microsoftonline.com/common'

    DEFAULT_URL = 'https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0'

    attr_reader :tenant_id,
                :username,
                :password,
                :application_id,
                :secret_key,
                :url,
                :oauth2_login_url,
                :oauth2_client,
                :default_company_id,
                :debug

    alias access_token oauth2_client

    object :account
    object :aged_account_payable
    object :aged_account_receivable
    object :balance_sheet
    object :cash_flow_statement
    object :company
    object :company_information
    object :country_region
    object :currency
    object :customer
    object :customer_financial_detail
    object :customer_payment
    object :customer_payment_journal
    object :customer_sale
    object :default_dimension
    object :dimension
    object :dimension_line
    object :dimension_value
    object :vendor
    object :purchase_invoice
    object :purchase_invoice_line
    object :item

    def initialize(options = {})
      opts = options.dup
      @tenant_id = opts.delete(:tenant_id)
      @username = opts.delete(:username)
      @password = opts.delete(:password)
      @url = opts.delete(:url) || DEFAULT_URL
      @application_id = opts.delete(:application_id)
      @secret_key = opts.delete(:secret_key)
      @oauth2_login_url = opts.delete(:oauth2_login_url) || DEFAULT_LOGIN_URL
      @default_company_id = opts.delete(:default_company_id)
      @debug = opts.delete(:debug) || false
    end

    def authorize(params = {}, oauth_authorize_callback: '')
      params[:redirect_uri] = oauth_authorize_callback
      begin
        oauth2_client.auth_code.authorize_url(params)
      rescue OAuth2::Error => e
        handle_error(e)
      end
    end

    def request_token(code = '', oauth_token_callback: '')
      oauth2_client.auth_code.get_token(code, redirect_uri: oauth_token_callback)
    rescue OAuth2::Error => e
      handle_error(e)
    end

    def authorize_from_token(token: '', refresh_token: '', expires_at: nil, expires_in: nil)
      @oauth2_client = OAuth2::AccessToken.new(
        oauth2_client,
        token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        expires_in: expires_in
      )
    end

    def refresh_token
      @oauth2_client.refresh!
    end

    private

    def oauth2_client
      if @oauth2_client.nil?
        @oauth2_client = OAuth2::Client.new(
          @application_id,
          @secret_key,
          site: @oauth2_login_url,
          authorize_url: 'oauth2/authorize?resource=https://api.businesscentral.dynamics.com',
          token_url: 'oauth2/token?resource=https://api.businesscentral.dynamics.com'
        )
      end

      @oauth2_client
    end

    def handle_error(error)
      raise ApiException, error.message if error.code.nil?

      case error.code
      when 'invalid_client'
        raise InvalidClientException
      end
    end
  end
end
