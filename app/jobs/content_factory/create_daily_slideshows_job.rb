module ContentFactory
  class CreateDailySlideshowsJob < ApplicationJob
    queue_as :default

    def perform(factory_date = Time.zone.today)
      Project.where(factory_enabled: true).find_each do |project|
        project.zernio_accounts.active.tiktok.where(provider: project.publishing_provider).find_each do |account|
          next unless account.factory_configured?

          account.factory_posts_per_day.times do |index|
            SlideshowCreator.new(project, zernio_account: account, factory_date:, factory_slot: index + 1).call
          rescue ContentFactory::SlideshowCreator::Error, ActiveRecord::RecordInvalid => error
            Rails.logger.warn("Content factory skipped account #{account.id}: #{error.message}")
          end
        end
      end
    end
  end
end
