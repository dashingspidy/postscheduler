class VideoCreation < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :post, optional: true

  has_one_attached :input_video
  has_one_attached :output_video

  enum :status, pending: "pending", processing: "processing", completed: "completed", failed: "failed"

  validates :input_video, presence: true
  validates :call_to_action, presence: true
end
