class ZernioAccount < ApplicationRecord
  PLATFORMS = %w[tiktok youtube facebook instagram].freeze

  belongs_to :project
  has_many :slideshow_import_targets, dependent: :destroy
  has_many :slideshow_imports, through: :slideshow_import_targets

  validates :account_id, :label, presence: true
  validates :platform, inclusion: { in: PLATFORMS }
  validates :provider, inclusion: { in: Publishing::Registry::PROVIDERS.keys }

  scope :tiktok, -> { where(platform: "tiktok") }
  scope :active, -> { where(active: true) }

  def tiktok? = platform == "tiktok"
end
