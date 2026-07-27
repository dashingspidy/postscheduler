class ZernioAccount < ApplicationRecord
  PLATFORMS = %w[tiktok youtube facebook instagram].freeze

  belongs_to :project
  has_many :slideshow_targets, dependent: :destroy
  has_many :slideshows, through: :slideshow_targets
  has_many :content_topics, dependent: :nullify
  has_many :factory_slideshows, class_name: "Slideshow", dependent: :nullify

  validates :account_id, :label, presence: true
  validates :platform, inclusion: { in: PLATFORMS }
  validates :provider, inclusion: { in: Publishing::Registry::PROVIDERS.keys }
  validates :factory_posts_per_day, numericality: { only_integer: true, in: 1..20 }

  scope :tiktok, -> { where(platform: "tiktok") }
  scope :active, -> { where(active: true) }

  def tiktok? = platform == "tiktok"

  def factory_configured?
    factory_enabled? && profile_content_strategy.present? && profile_content_pillars.any?
  end

  def profile_content_strategy = content_strategy
  def profile_content_pillars = content_pillars
  def profile_pillar_weight(pillar)
    content_pillar_weights.fetch(pillar, 1).to_i.clamp(1, 100)
  end

  def content_pillars_text
    profile_content_pillars.map { |pillar| "#{pillar} | #{profile_pillar_weight(pillar)}" }.join("\n")
  end

  def content_pillars_text=(value)
    entries = value.to_s.lines.filter_map do |line|
      name, weight = line.split("|", 2).map { |part| part.to_s.strip }
      next if name.blank?

      [ name, Integer(weight.to_s.delete_suffix("%"), exception: false).to_i ]
    end
    self.content_pillars = entries.map(&:first).uniq
    self.content_pillar_weights = entries.to_h { |name, weight| [ name, weight.positive? ? weight : 1 ] }
  end
end
