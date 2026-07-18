class AddPublishingProviderToProjectsPostsAndAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :publishing_provider, :string, null: false, default: "zernio"
    add_column :posts, :publishing_provider, :string, null: false, default: "zernio"
    add_column :zernio_accounts, :provider, :string, null: false, default: "zernio"

    remove_index :zernio_accounts, name: "index_zernio_accounts_on_project_id_and_account_id"
    add_index :zernio_accounts, %i[project_id provider account_id], unique: true
  end
end
