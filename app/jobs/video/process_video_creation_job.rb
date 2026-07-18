require "tempfile"

module Video
  class ProcessVideoCreationJob < ApplicationJob
    queue_as :default

    def perform(video_creation)
      return if video_creation.completed?

      video_creation.update!(status: :processing, error_message: nil)
      raise "Video creation is missing its post." unless video_creation.post
      video_creation.input_video.open do |input|
        Tempfile.create([ "video-creation", ".mp4" ]) do |output|
          Video::EndCardConcatenator.call(
            input_path: input.path,
            project: video_creation.project,
            output_path: output.path,
            call_to_action: video_creation.call_to_action
          )
          output.rewind
          video_creation.output_video.attach(
            io: output,
            filename: "#{video_creation.project.name.parameterize}-with-end-card.mp4",
            content_type: "video/mp4"
          )
          video_creation.post.video.attach(video_creation.output_video.blob)
        end
      end
      video_creation.update!(status: :completed)
    rescue StandardError => error
      video_creation.update!(status: :failed, error_message: error.message)
      raise
    end
  end
end
