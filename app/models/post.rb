class Post < ApplicationRecord
  PLATFORMS = %w[facebook instagram tiktok youtube].freeze

  belongs_to :user
  belongs_to :project, optional: true
  has_many_attached :slides
  has_one_attached :video
  has_one :slideshow_item, dependent: :nullify
  has_one :video_creation, dependent: :nullify

  validates :content, presence: true
  validates :platforms, presence: true
  validates :status, inclusion: { in: %w[draft scheduled publishing published failed] }
  validate :supported_platforms

  scope :scheduled, -> { where.not(scheduled_at: nil) }

  enum :delivery_mode, tiktok_draft: "tiktok_draft", auto_publish: "auto_publish"
  validates :publishing_provider, inclusion: { in: Publishing::Registry::PROVIDERS.keys }

  private
    def supported_platforms
      invalid_platforms = Array(platforms) - PLATFORMS
      errors.add(:platforms, "contains an unsupported platform") if invalid_platforms.any?
    end
end
