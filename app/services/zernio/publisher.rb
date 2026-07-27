module Zernio
  class Publisher
    def self.call(post, client: Client.new)
      new(post, client:).call
    end

    def initialize(post, client:)
      @post = post
      @client = client
    end

    def call
      response = @client.posts.create_post(request)
      @post.update!(provider_post_id: response.post._id, zernio_post_id: response.post._id, status: response.post.status)
      response
    rescue Zernio::ApiError => e
      @post.update!(status: "failed")
      raise e
    end

    private
      def request
        Zernio::CreatePostRequest.new(
          title: @post.title.presence,
          content: @post.content,
          media_items: media_items,
          # Zernio's top-level draft only saves inside Zernio. TikTok Creator
          # Inbox drafts are dispatched immediately and controlled by
          # tiktok_settings.draft below.
          publish_now: true,
          is_draft: false,
          timezone: @post.project&.time_zone || Time.zone.tzinfo.name,
          platforms: targets,
          tiktok_settings: tiktok_settings
        )
      end

      def targets
        @post.platforms.flat_map do |platform|
          account_ids = Array(@post.account_ids[platform]).compact_blank
          raise ArgumentError, "Missing Zernio account ID for #{platform}" if account_ids.empty?

          account_ids.map { |account_id| Zernio::CreatePostRequestPlatformsInner.new(platform:, account_id:) }
        end
      end

      def media_items
        uploader = MediaUploader.new(@client)
        if @post.video.attached?
          return [ Zernio::MediaItem.new(type: "video", url: uploader.upload(@post.video), filename: @post.video.filename.to_s, mime_type: @post.video.content_type, size: @post.video.byte_size) ]
        end
        return if @post.slides.empty?

        @post.slides.map do |slide|
          Zernio::MediaItem.new(type: "image", url: uploader.upload(slide), filename: slide.filename.to_s, mime_type: slide.content_type, size: slide.byte_size)
        end
      end

      def tiktok_settings
        return unless @post.platforms.include?("tiktok")

        creator_info = @client.accounts.get_tik_tok_creator_info(tiktok_account_id, media_type: @post.video.attached? ? "video" : "photo")
        privacy_level = creator_info.privacy_levels.find { |level| level.value == "PUBLIC_TO_EVERYONE" } || creator_info.privacy_levels.first
        raise "TikTok account has no available privacy level." unless privacy_level

        Zernio::TikTokPlatformData.new(
          draft: @post.tiktok_draft?,
          privacy_level: privacy_level.value,
          allow_comment: true,
          content_preview_confirmed: true,
          express_consent_given: true,
          media_type: @post.video.attached? ? "video" : "photo",
          photo_cover_index: @post.video.attached? ? nil : 0,
          description: @post.content
        )
      end

      def tiktok_account_id
        Array(@post.account_ids["tiktok"]).compact_blank.first || raise(ArgumentError, "Missing TikTok account ID")
      end
  end
end
