module Publishing
  class Registry
    PROVIDERS = {
      "zernio" => Providers::Zernio,
      "post_for_me" => Providers::PostForMe
    }.freeze

    def self.fetch(name)
      PROVIDERS.fetch(name.to_s) { raise ArgumentError, "Unsupported publishing provider: #{name}" }.new
    end

    def self.options
      PROVIDERS.filter_map do |provider, adapter|
        [ provider.humanize, provider ] unless adapter.respond_to?(:configured?) && !adapter.configured?
      end
    end
  end
end
