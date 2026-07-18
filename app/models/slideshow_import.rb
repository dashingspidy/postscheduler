class SlideshowImport < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_one_attached :csv_file
  has_many :slideshow_items, dependent: :destroy
  has_many :slideshow_import_targets, dependent: :destroy
  has_many :zernio_accounts, through: :slideshow_import_targets

  before_validation :assign_tiktok_account_id
  validate :has_tiktok_target
  validates :csv_file, presence: true
  validate :has_background_images

  enum :status, pending: "pending", processing: "processing", completed: "completed", failed: "failed"
  enum :delivery_mode, tiktok_draft: "tiktok_draft", auto_publish: "auto_publish"

  before_validation :assign_first_delivery_at, on: :create

  def background_images = project.background_images

  def delivery_at_for(position)
    first_delivery_at + (position / 5).days
  end

  private
    def assign_tiktok_account_id
      self.tiktok_account_id = zernio_accounts.to_a.find(&:tiktok?)&.account_id
    end

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
