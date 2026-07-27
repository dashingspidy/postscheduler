module TikTok
  class ProcessSlideshowJob < ApplicationJob
    queue_as :default

    def perform(slideshow)
      SlideshowTextGenerator.new(slideshow).call
    end
  end
end
