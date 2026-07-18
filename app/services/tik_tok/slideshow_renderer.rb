require "fileutils"
require "json"
require "open3"
require "tmpdir"

module TikTok
  class SlideshowRenderer
    class Error < StandardError; end

    SCRIPT_PATH = Rails.root.join("python/slideshow_renderer.py").freeze

    def initialize(item)
      @item = item
      @import = item.slideshow_import
    end

    def call
      post = @item.post || @import.user.posts.create!(post_attributes)
      post.slides.purge

      Dir.mktmpdir("slideshow-render") do |directory|
        output_paths = render_into(directory)
        output_paths.each_with_index do |path, index|
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
          title: data["title"].presence || data["day"],
          content: data["caption"].presence || slides.join("\n"),
          scheduled_at: @import.delivery_at_for(@item.position),
          platforms: [ "tiktok" ],
          project: @import.project,
          account_ids: @import.zernio_accounts.group_by(&:platform).transform_values { |accounts| accounts.map(&:account_id) },
          publishing_provider: @import.project.publishing_provider,
          delivery_mode: @import.delivery_mode,
          status: "scheduled"
        }
      end

      def render_into(directory)
        payload = {
          slides:,
          tactic: data["tactic"],
          style:,
          background_images: local_backgrounds(directory),
          background_offset: @item.position * slides.length,
          output_directory: File.join(directory, "output")
        }
        stdout, stderr, status = Open3.capture3(python_binary, SCRIPT_PATH.to_s, stdin_data: payload.to_json)
        raise Error, "Pillow renderer failed: #{stderr.presence || stdout}" unless status.success?

        result = JSON.parse(stdout)
        raise Error, result.fetch("error", "Pillow renderer returned no slide files.") if result["error"].present?
        paths = result.fetch("slides")
        raise Error, "Pillow renderer returned an unexpected number of slides." unless paths.size == slides.size && paths.all? { |path| File.file?(path) }

        paths
      rescue JSON::ParserError, KeyError => error
        raise Error, "Pillow renderer returned invalid JSON: #{error.message}"
      end

      def local_backgrounds(directory)
        @import.background_images.each_with_index.map do |attachment, index|
          extension = attachment.filename.extension_with_delimiter.presence || ".jpg"
          destination = File.join(directory, "background-#{index}#{extension}")
          attachment.open { |file| FileUtils.cp(file.path, destination) }
          destination
        end
      end

      def python_binary = ENV.fetch("PILLOW_PYTHON", "python3")

      def data = @item.data
      def slides = data.fetch("slides")
      def safe_filename = data["day"].to_s.parameterize.presence || "slideshow"
      def style = @import.project.rendering_style
  end
end
