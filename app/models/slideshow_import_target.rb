class SlideshowImportTarget < ApplicationRecord
  belongs_to :slideshow_import
  belongs_to :zernio_account

  validate :account_belongs_to_import_project

  private
    def account_belongs_to_import_project
      errors.add(:zernio_account, "must belong to the selected project") if slideshow_import && zernio_account && slideshow_import.project_id != zernio_account.project_id
    end
end
