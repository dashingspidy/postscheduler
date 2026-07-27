class Project < ApplicationRecord
  DEFAULT_STYLE = {
    "text_color" => "black",
    "stroke_color" => "white",
    "font_size" => 58,
    "tactic_font_size" => 38,
    "tactic_top_margin" => 240,
    "caption_background_color" => "white",
    "caption_background_padding_x" => 28,
    "caption_background_padding_y" => 16,
    "caption_background_radius" => 18
  }.freeze

  belongs_to :user
  has_one_attached :app_icon
  has_one_attached :end_slide_branding
  has_many_attached :background_images
  has_many :zernio_accounts, dependent: :destroy
  has_many :slideshows, dependent: :restrict_with_error
  has_many :content_topics, dependent: :destroy
  has_many :video_creations, dependent: :restrict_with_error
  has_many :posts, dependent: :nullify

  validates :name, presence: true
  validates :default_slide_count, numericality: { only_integer: true, in: 3..10 }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:tzinfo).map(&:name) }
  validate :factory_time_is_valid

  validates :publishing_provider, inclusion: { in: Publishing::Registry::PROVIDERS.keys }

  def rendering_style
    DEFAULT_STYLE.merge(style || {})
  end

  def factory_ready?
    factory_enabled? && factory_configured?
  end

  def factory_configured?
    background_images.attached? && zernio_accounts.active.tiktok.where(provider: publishing_provider).any?(&:factory_configured?)
  end

  # Store canonical IANA identifiers even when a human-friendly Rails zone name
  # is submitted from an older form or API client.
  def time_zone=(value)
    zone = ActiveSupport::TimeZone[value]
    super(zone&.tzinfo&.name || value)
  end

  def time_zone_object = ActiveSupport::TimeZone[time_zone]

  private
    def factory_time_is_valid
      Time.strptime(factory_time.to_s, "%H:%M")
    rescue ArgumentError
      errors.add(:factory_time, "must be in HH:MM format")
    end
end
