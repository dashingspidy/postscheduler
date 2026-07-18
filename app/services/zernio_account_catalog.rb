class ZernioAccountCatalog
  def self.call
    Publishing::Registry.fetch("zernio").list_accounts
  end
end
