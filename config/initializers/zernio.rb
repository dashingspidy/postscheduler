require "zernio-sdk"

Zernio.configure do |config|
  config.access_token = Rails.application.credentials.dig(:zernio, :api_key)
end
