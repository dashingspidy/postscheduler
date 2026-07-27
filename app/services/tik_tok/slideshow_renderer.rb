require "fileutils"
require "json"
require "open3"
require "tmpdir"

module TikTok
  class SlideshowRenderer
    class Error < StandardError; end

    SCRIPT_PATH = Rails.root.join("python/slideshow_renderer.py").freeze

    def initialize(slideshow)
      @slideshow = slideshow
    end

    def call
      post = @slideshow.post || @slideshow.user.posts.create!(post_attributes)
      @slideshow.update!(post:) unless @slideshow.post_id == post.id
      post.slides.purge

      Dir.mktmpdir("slideshow-render") do |directory|
        render_into(directory).each_with_index do |path, index|
          File.open(path, "rb") do |file|
            post.slides.attach(io: file, filename: "#{safe_filename}_slide_#{index + 1}.jpg", content_type: "image/jpeg")
          end
        end
      end
      post
    end

    private
      def post_attributes
        {
          title: data["title"],
          content: data["caption"].presence || slides.join("\n"),
          scheduled_at: @slideshow.first_delivery_at,
          platforms: [ "tiktok" ],
          project: @slideshow.project,
          account_ids: @slideshow.zernio_accounts.group_by(&:platform).transform_values { |accounts| accounts.map(&:account_id) },
          publishing_provider: @slideshow.project.publishing_provider,
          delivery_mode: @slideshow.delivery_mode,
          status: "scheduled"
        }
      end

      def render_into(directory)
        payload = {
          slides:,
          top_label: data["title"],
          style:,
          background_images: local_backgrounds(directory),
          end_slide_branding: local_end_slide_branding(directory),
          output_directory: File.join(directory, "output")
        }
        stdout, stderr, status = Open3.capture3(python_binary, SCRIPT_PATH.to_s, stdin_data: payload.to_json)
        raise Error, "Pillow renderer failed: #{stderr.presence || stdout}" unless status.success?

        paths = JSON.parse(stdout).fetch("slides")
        raise Error, "Pillow renderer returned an unexpected number of slides." unless paths.size == slides.size && paths.all? { |path| File.file?(path) }

        paths
      rescue JSON::ParserError, KeyError => error
        raise Error, "Pillow renderer returned invalid JSON: #{error.message}"
      end

      def local_backgrounds(directory)
        @slideshow.background_images.each_with_index.map do |attachment, index|
          extension = attachment.filename.extension_with_delimiter.presence || ".jpg"
          destination = File.join(directory, "background-#{index}#{extension}")
          attachment.open { |file| FileUtils.cp(file.path, destination) }
          destination
        end
      end

      def local_end_slide_branding(directory)
        attachment = @slideshow.project.end_slide_branding
        return unless attachment.attached?

        extension = attachment.filename.extension_with_delimiter.presence || ".png"
        destination = File.join(directory, "end-slide-branding#{extension}")
        attachment.open { |file| FileUtils.cp(file.path, destination) }
        destination
      end

      def python_binary = ENV.fetch("PILLOW_PYTHON", "python3")
      def data = @slideshow.data
      def slides = data.fetch("slides")
      def safe_filename = data["title"].to_s.parameterize.presence || "slideshow"
      def style = @slideshow.project.rendering_style
  end
end
