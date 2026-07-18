module TikTok
  class ProcessSlideshowImportJob < ApplicationJob
    queue_as :default

    def perform(import)
      SlideshowImportParser.new(import).call
    end
  end
end
