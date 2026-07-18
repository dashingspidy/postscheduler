class CreateZernioAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :zernio_accounts do |t|
      t.references :project, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :account_id, null: false
      t.string :label, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :zernio_accounts, %i[project_id account_id], unique: true

    create_table :slideshow_import_targets do |t|
      t.references :slideshow_import, null: false, foreign_key: true
      t.references :zernio_account, null: false, foreign_key: true
      t.timestamps
    end
    add_index :slideshow_import_targets, %i[slideshow_import_id zernio_account_id], unique: true, name: :index_slideshow_import_targets_uniqueness

    change_column_null :projects, :tiktok_account_id, true
    change_column_null :slideshow_imports, :tiktok_account_id, true
  end
end
