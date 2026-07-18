require "net/http"

module Zernio
  class MediaUploader
    def initialize(client)
      @client = client
    end

    def upload(attachment)
      presigned = @client.media.get_media_presigned_url(
        Zernio::GetMediaPresignedUrlRequest.new(filename: attachment.filename.to_s, content_type: attachment.content_type)
      )
      attachment.open do |file|
        response = Net::HTTP.start(URI(presigned.upload_url).host, URI(presigned.upload_url).port, use_ssl: true) do |http|
          request = Net::HTTP::Put.new(URI(presigned.upload_url))
          request["Content-Type"] = attachment.content_type
          request.body_stream = file
          request.content_length = attachment.byte_size
          http.request(request)
        end
        raise "Zernio media upload failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)
      end
      presigned.public_url
    end
  end
end
