require "json"
require "openai"

module TikTok
  class SlideshowTextGenerator
    class Error < StandardError; end
    class InvalidResponse < Error; end

    BEDROCK_REGION = "us-east-1"
    BEDROCK_MODEL = "google.gemma-4-26b-a4b"

    def initialize(slideshow)
      @slideshow = slideshow
    end

    def call
      data = generate_data

      @slideshow.update!(data:, status: :rendering, error_message: nil)
      @slideshow.content_topic&.update!(title: data.fetch("title"))
      TikTok::RenderSlideshowJob.perform_later(@slideshow)
    rescue StandardError => error
      @slideshow.update!(status: :failed, error_message: error.message)
      @slideshow.content_topic&.update!(status: :failed)
      raise Error, error.message
    end

    private

      def client
        OpenAI::Client.new(
          access_token: credentials.fetch(:api_key),
          uri_base: "https://bedrock-mantle.#{BEDROCK_REGION}.api.aws/openai/v1",
          request_timeout: 60
        )
      end

      def credentials
        @credentials ||= Rails.application.credentials.fetch(:bedrock)
      rescue KeyError
        raise Error, "Bedrock is not configured. Add bedrock.api_key to Rails credentials."
      end

      def request_parameters
        {
          model: BEDROCK_MODEL,
          temperature: 0.7,
          max_tokens: 2_048,
          response_format: { type: "json_object" },
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: "Create the slideshow for this brief:\n#{@slideshow.prompt}" }
          ]
        }
      end

      def system_prompt
        <<~PROMPT
          You write concise, engaging TikTok carousel text. Return only valid JSON with exactly these keys:
          title (string), caption (string), slides (array of #{@slideshow.slide_count} strings).
          Make every slide self-contained, readable on a phone, and at most 180 characters. The first slide must follow the required hook style from the brief, while the title and all slides must remain faithful to its required angle. The final slide must include a concise call to action. Do not add markdown, hashtags, or keys beyond the requested schema.
        PROMPT
      end

      def parse_response(content)
        parsed = JSON.parse(json_payload(content))
        title = parsed.fetch("title").to_s.strip
        caption = parsed.fetch("caption").to_s.strip
        slides = Array(parsed.fetch("slides")).map { |slide| slide.to_s.strip }.reject(&:blank?)
        raise InvalidResponse, "Gemma returned an empty title." if title.blank?
        raise InvalidResponse, "Gemma returned #{slides.length} slides; expected #{@slideshow.slide_count}." unless slides.length == @slideshow.slide_count
        raise InvalidResponse, "Gemma returned slide text that is too long." if slides.any? { |slide| slide.length > 180 }

        { "title" => title, "caption" => caption.presence || title, "slides" => slides }
      rescue JSON::ParserError, KeyError => error
        raise InvalidResponse, "Gemma returned invalid slideshow data: #{error.message}"
      end

      def generate_data
        attempts = 0
        begin
          attempts += 1
          content = client.chat(parameters: request_parameters).dig("choices", 0, "message", "content")
          parse_response(content)
        rescue InvalidResponse
          retry if attempts < 2
          raise
        end
      end

      def json_payload(content)
        content.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
      end
  end
end
