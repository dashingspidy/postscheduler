module Publishing
  module Providers
    class Zernio
      def list_accounts
        ::Zernio::AccountsApi.new.list_accounts.accounts.map do |account|
          Publishing::Account.new(
            id: account._id,
            platform: account.platform,
            label: account.display_name.presence || account.username.presence || account._id,
            active: account.is_active && account.enabled != false
          )
        end
      end

      def publish(post)
        ::Zernio::Publisher.call(post)
      end
    end
  end
end
