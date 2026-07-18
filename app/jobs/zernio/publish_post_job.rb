module Zernio
  class PublishPostJob < ApplicationJob
    queue_as :default
    retry_on Zernio::ApiError, wait: :polynomially_longer, attempts: 3

    def perform(post)
      return if post.provider_post_id.present?

      post.update!(status: "publishing")
      Publishing::Dispatcher.publish(post)
    rescue StandardError
      post.update!(status: "failed") if post.persisted?
      raise
    end
  end
end
