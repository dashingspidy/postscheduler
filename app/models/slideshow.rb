class Slideshow < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :post, optional: true
  belongs_to :content_topic, optional: true
  belongs_to :zernio_account, optional: true
  has_many :slideshow_targets, dependent: :destroy
  has_many :zernio_accounts, through: :slideshow_targets

  validates :prompt, presence: true, length: { maximum: 10_000 }
  validates :slide_count, numericality: { only_integer: true, in: 3..10 }
  validate :has_tiktok_target
  validate :has_background_images

  enum :status, pending: "pending", generating: "generating", rendering: "rendering", ready: "ready", failed: "failed"
  enum :delivery_mode, tiktok_draft: "tiktok_draft", auto_publish: "auto_publish"

  before_validation :assign_first_delivery_at, on: :create

  def background_images = project.background_images

  private
    def has_tiktok_target
      errors.add(:zernio_accounts, "must include at least one active TikTok account") unless zernio_accounts.any?(&:tiktok?)
    end

    def has_background_images
      errors.add(:project, "must have at least one uploaded photo") unless project&.background_images&.attached?
    end

    def assign_first_delivery_at
      return if first_delivery_at.present?

      today_at_nine = Time.zone.today.in_time_zone.change(hour: 9)
      self.first_delivery_at = today_at_nine.future? ? today_at_nine : today_at_nine + 1.day
    end
end
