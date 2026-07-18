require "zernio-sdk"

module Zernio
  class Client
    def initialize(api_client: Zernio::ApiClient.default)
      @api_client = api_client
    end

    def posts
      @posts ||= Zernio::PostsApi.new(@api_client)
    end

    def accounts
      @accounts ||= Zernio::AccountsApi.new(@api_client)
    end

    def connect
      @connect ||= Zernio::ConnectApi.new(@api_client)
    end

    def media
      @media ||= Zernio::MediaApi.new(@api_client)
    end
  end
end
