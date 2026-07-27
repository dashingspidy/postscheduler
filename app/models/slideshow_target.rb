class SlideshowTarget < ApplicationRecord
  belongs_to :slideshow
  belongs_to :zernio_account

  validate :account_belongs_to_slideshow_project

  private
    def account_belongs_to_slideshow_project
      return unless slideshow && zernio_account && slideshow.project_id != zernio_account.project_id

      errors.add(:zernio_account, "must belong to the selected project")
    end
end
