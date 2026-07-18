class SlideshowItem < ApplicationRecord
  belongs_to :slideshow_import
  belongs_to :post, optional: true

  enum :status, pending: "pending", rendering: "rendering", ready: "ready", failed: "failed"

  delegate :user, to: :slideshow_import
end
