require "json"
require "open3"
require "tempfile"

module Video
  class EndCardConcatenator
    WIDTH = 1080
    HEIGHT = 1920
    END_CARD_DURATION = 2

    def self.call(input_path:, project:, output_path:, call_to_action: "Download the app")
      new(input_path:, project:, output_path:, call_to_action:).call
    end

    def initialize(input_path:, project:, output_path:, call_to_action:)
      @input_path = input_path.to_s
      @project = project
      @output_path = output_path.to_s
      @call_to_action = call_to_action
    end

    def call
      raise ArgumentError, "Project needs an app icon." unless @project.app_icon.attached?
      raise ArgumentError, "Input video does not exist." unless File.file?(@input_path)
      raise "FFmpeg must be built with the drawtext filter." unless drawtext_available?

      Dir.mktmpdir("end-card") do |directory|
        normalized_video = File.join(directory, "normalized.mp4")
        end_card = File.join(directory, "end-card.mp4")

        normalize_video(normalized_video)
        @project.app_icon.open { |icon| render_end_card(icon.path, end_card, directory) }
        concatenate(normalized_video, end_card, directory)
      end
      @output_path
    end

    private
      def normalize_video(output)
        audio_input = has_audio? ? [] : [ "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000" ]
        audio_map = has_audio? ? "0:a:0" : "1:a:0"
        run_ffmpeg("-i", @input_path, *audio_input, "-map", "0:v:0", "-map", audio_map,
          "-vf", "scale=#{WIDTH}:#{HEIGHT}:force_original_aspect_ratio=increase,crop=#{WIDTH}:#{HEIGHT},fps=30",
          "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", "-ar", "48000", "-shortest", output)
      end

      def render_end_card(icon_path, output, directory)
        title_file = write_text_file(directory, "title.txt", @project.name)
        cta_file = write_text_file(directory, "cta.txt", @call_to_action)
        background = @project.rendering_style.fetch("end_card_background_color", "#0f172a")
        filter = "[1:v]scale=260:-1[icon];[0:v][icon]overlay=(W-w)/2:500," \
          "drawtext=fontcolor=white:fontsize=64:textfile='#{filter_path(title_file)}':x=(w-text_w)/2:y=850," \
          "drawtext=fontcolor=white:fontsize=42:textfile='#{filter_path(cta_file)}':x=(w-text_w)/2:y=970[out]"
        run_ffmpeg("-f", "lavfi", "-i", "color=c=#{background}:s=#{WIDTH}x#{HEIGHT}:r=30", "-loop", "1", "-i", icon_path,
          "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000", "-filter_complex", filter,
          "-map", "[out]", "-map", "2:a:0", "-t", END_CARD_DURATION.to_s, "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", output)
      end

      def concatenate(video, end_card, directory)
        list = File.join(directory, "concat.txt")
        File.write(list, "file '#{video}'\nfile '#{end_card}'\n")
        run_ffmpeg("-f", "concat", "-safe", "0", "-i", list, "-c", "copy", "-movflags", "+faststart", @output_path)
      end

      def has_audio?
        output, status = Open3.capture2("ffprobe", "-v", "error", "-select_streams", "a", "-show_entries", "stream=index", "-of", "json", @input_path)
        status.success? && JSON.parse(output).fetch("streams", []).any?
      end

      def drawtext_available?
        filters, status = Open3.capture2("ffmpeg", "-hide_banner", "-filters")
        status.success? && filters.include?("drawtext")
      end

      def write_text_file(directory, name, text)
        path = File.join(directory, name)
        File.write(path, text.to_s)
        path
      end

      def filter_path(path)
        path.gsub("\\", "\\\\").gsub(":", "\\:").gsub("'", "\\\\\\'")
      end

      def run_ffmpeg(*arguments)
        _output, status = Open3.capture2e("ffmpeg", "-y", "-loglevel", "error", *arguments)
        raise "FFmpeg failed: #{_output}" unless status.success?
      end
  end
end
