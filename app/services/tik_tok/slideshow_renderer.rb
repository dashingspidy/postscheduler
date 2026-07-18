require "mini_magick"
require "tempfile"

module TikTok
  class SlideshowRenderer
    WIDTH = 1080
    HEIGHT = 1920

    def initialize(item)
      @item = item
      @import = item.slideshow_import
    end

    def call
      post = @item.post || @import.user.posts.create!(post_attributes)
      post.slides.purge

      slides.each_with_index do |text, index|
        rendered_slide(text, index).open do |file|
          post.slides.attach(io: file, filename: "#{safe_filename}_slide_#{index + 1}.jpg", content_type: "image/jpeg")
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

      def rendered_slide(text, index)
        source = @import.background_images[(slide_offset + index) % @import.background_images.count]
        source.open do |file|
          image = MiniMagick::Image.open(file.path)
          image.combine_options do |command|
            command.resize "#{WIDTH}x#{HEIGHT}^"
            command.gravity "center"
            command.extent "#{WIDTH}x#{HEIGHT}"
            command.fill style["text_color"]
            command.stroke style["stroke_color"]
            command.strokewidth "3"
            command.pointsize style["font_size"].to_s
            command.gravity "center"
            command.annotate "+0+0", text
            if index.zero? && data["tactic"].present?
              command.fill style["text_color"]
              command.stroke style["stroke_color"]
              command.strokewidth "2"
              command.pointsize style["tactic_font_size"].to_s
              command.gravity "north"
              command.annotate "+0+#{style["tactic_top_margin"]}", data["tactic"]
            end
            command.quality "95"
          end
          output = Tempfile.new([ "tiktok-slide", ".jpg" ])
          image.write(output.path)
          output.rewind
          return output
        end
      end

      def data = @item.data
      def slides = data.fetch("slides")
      def slide_offset = @item.position * slides.length
      def safe_filename = data["day"].to_s.parameterize.presence || "slideshow"
      def style = @import.project.rendering_style
  end
end
