class AddDeliverySettingsToSlideshowsAndPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :slideshow_imports, :delivery_mode, :string, null: false, default: "tiktok_draft"
    add_column :slideshow_imports, :first_delivery_at, :datetime
    add_column :posts, :delivery_mode, :string, null: false, default: "auto_publish"
  end
end
