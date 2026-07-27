class ContentTopic < ApplicationRecord
  belongs_to :project
  belongs_to :zernio_account, optional: true
  belongs_to :slideshow, optional: true

  enum :status, planned: "planned", generating: "generating", ready: "ready", failed: "failed"
end
