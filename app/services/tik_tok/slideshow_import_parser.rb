require "csv"

module TikTok
  class SlideshowImportParser
    def initialize(import)
      @import = import
    end

    def call
      csv = @import.csv_file.download.encode("UTF-8", invalid: :replace, undef: :replace).sub(/\A\uFEFF/, "")
      rows = CSV.parse(csv, headers: true)
      raise ArgumentError, "The CSV must include headers." if rows.headers.blank?

      headers = rows.headers.to_h { |header| [header.downcase, header] }
      slide_columns = headers.values.grep(/\Aslide\d+\z/i).sort_by { |header| header[/\d+/].to_i }
      raise ArgumentError, "The CSV must include Slide1, Slide2, and so on." if slide_columns.empty?

      items = rows.each_with_index.filter_map do |row, position|
        slides = slide_columns.filter_map { |column| row[column].to_s.strip.presence }
        next if row.to_h.values.all?(&:blank?)

        day = value(row, headers, "day")
        raise ArgumentError, "Row #{position + 2} is missing Day." if day.blank?
        raise ArgumentError, "Row #{position + 2} has no slide text." if slides.empty?

        { position:, data: { "day" => day, "tactic" => value(row, headers, "tactic"), "title" => value(row, headers, "title"), "caption" => caption_for(row, headers), "slides" => slides, "scheduled_at" => value(row, headers, "scheduled_at") } }
      end
      raise ArgumentError, "The CSV contains no slideshow rows." if items.empty?

      SlideshowItem.transaction do
        @import.slideshow_items.destroy_all
        @import.slideshow_items.create!(items)
        @import.update!(status: :processing, total_rows: items.size, completed_rows: 0, failed_rows: 0, error_message: nil)
      end
      @import.slideshow_items.find_each { |item| TikTok::RenderSlideshowJob.perform_later(item) }
    rescue StandardError => e
      @import.update!(status: :failed, error_message: e.message)
      raise
    end

    private
      def value(row, headers, name)
        row[headers[name]]&.strip
      end

      def caption_for(row, headers)
        [value(row, headers, "caption"), value(row, headers, "title"), value(row, headers, "keywords"), value(row, headers, "hashtags")].compact_blank.join("\n\n")
      end
  end
end
