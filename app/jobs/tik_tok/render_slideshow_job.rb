require "mini_magick"

module TikTok
  class RenderSlideshowJob < ApplicationJob
    queue_as :default
    retry_on MiniMagick::Error, wait: :polynomially_longer, attempts: 3

    def perform(item)
      return if item.ready?

      item.update!(status: :rendering, error_message: nil)
      post = SlideshowRenderer.new(item).call
      item.update!(post:, status: :ready)
      Zernio::PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post)
      refresh_import(item.slideshow_import)
    rescue StandardError => e
      item.update!(status: :failed, error_message: e.message)
      refresh_import(item.slideshow_import)
      raise
    end

    private
      def refresh_import(import)
        completed = import.slideshow_items.ready.count
        failed = import.slideshow_items.failed.count
        status = completed + failed == import.total_rows ? (failed.positive? ? :failed : :completed) : :processing
        import.update!(completed_rows: completed, failed_rows: failed, status:)
      end
  end
end
