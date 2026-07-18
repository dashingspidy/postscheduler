require "json"
require "net/http"

module Publishing
  module Providers
    class PostForMe
      API_URL = "https://api.postforme.dev".freeze

      def self.configured?
        Rails.application.credentials.dig(:post_for_me, :api_key).present?
      end

      def list_accounts
        response = get("/v1/social-accounts?limit=100")
        Array(response.fetch("data")).map do |account|
          Publishing::Account.new(
            id: account.fetch("id"),
            platform: account.fetch("platform"),
            label: account["display_name"].presence || account["username"].presence || account.fetch("id"),
            active: account.fetch("status", "connected") == "connected"
          )
        end
      end

      def publish(post)
        media = media_for(post)
        response = post_json("/v1/social-posts", {
          caption: post.content,
          social_accounts: post.account_ids.values.flatten.compact_blank,
          media:
        })
        provider_post_id = response["id"] || response.dig("data", "id")
        raise "PostForMe did not return a post ID." if provider_post_id.blank?

        status = response["status"] || response.dig("data", "status") || "published"
        status = "published" unless %w[draft scheduled publishing published failed].include?(status)
        post.update!(provider_post_id:, status:)
      end

      private

        def media_for(post)
          attachments = post.video.attached? ? [ post.video ] : post.slides.to_a
          attachments.map { |attachment| { url: upload(attachment) } }
        end

        def upload(attachment)
          urls = post_json("/v1/media/create-upload-url", {})
          upload_url = urls.fetch("upload_url")
          media_url = urls.fetch("media_url")
          uri = URI(upload_url)
          attachment.open do |file|
            request = Net::HTTP::Put.new(uri)
            request["Content-Type"] = attachment.content_type
            request.body = file.read
            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
            raise "PostForMe media upload failed (#{response.code})." unless response.is_a?(Net::HTTPSuccess)
          end
          media_url
        end

        def get(path)
          request_json(Net::HTTP::Get.new(path))
        end

        def post_json(path, payload)
          request = Net::HTTP::Post.new(path)
          request["Content-Type"] = "application/json"
          request.body = payload.to_json
          request_json(request)
        end

        def request_json(request)
          request["Authorization"] = "Bearer #{api_key}"
          response = Net::HTTP.start(URI(API_URL).host, URI(API_URL).port, use_ssl: true) { |http| http.request(request) }
          body = JSON.parse(response.body.presence || "{}")
          return body if response.is_a?(Net::HTTPSuccess)

          raise "PostForMe API error (#{response.code}): #{body["message"] || response.body}"
        end

        def api_key
          Rails.application.credentials.dig(:post_for_me, :api_key).presence || raise("PostForMe API key is not configured.")
        end
    end
  end
end
