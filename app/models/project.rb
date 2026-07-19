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
  has_many_attached :background_images
  has_many :zernio_accounts, dependent: :destroy
  has_many :slideshow_imports, dependent: :restrict_with_error
  has_many :video_creations, dependent: :restrict_with_error
  has_many :posts, dependent: :nullify

  validates :name, presence: true

  validates :publishing_provider, inclusion: { in: Publishing::Registry::PROVIDERS.keys }

  def rendering_style
    DEFAULT_STYLE.merge(style || {})
  end
end
