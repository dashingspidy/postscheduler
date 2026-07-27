module TikTok
  class RenderSlideshowJob < ApplicationJob
    queue_as :default
    retry_on SlideshowRenderer::Error, wait: :polynomially_longer, attempts: 3

    def perform(slideshow)
      return if slideshow.ready?

      slideshow.update!(status: :rendering, error_message: nil)
      post = SlideshowRenderer.new(slideshow).call
      slideshow.update!(post:, status: :ready)
      slideshow.content_topic&.update!(status: :ready)
      Zernio::PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post)
    rescue StandardError => e
      slideshow.update!(status: :failed, error_message: e.message)
      slideshow.content_topic&.update!(status: :failed)
      raise
    end
  end
end
