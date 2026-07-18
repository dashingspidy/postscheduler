class AddProviderPostIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :provider_post_id, :string
    add_index :posts, %i[publishing_provider provider_post_id], unique: true
  end
end
