class AddContentFactoryToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :content_strategy, :text
    add_column :projects, :content_pillars, :json, null: false, default: []
    add_column :projects, :factory_enabled, :boolean, null: false, default: false
    add_column :projects, :factory_time, :string, null: false, default: "09:00"
    add_column :projects, :default_slide_count, :integer, null: false, default: 5
    add_column :projects, :default_delivery_mode, :string, null: false, default: "tiktok_draft"
  end
end
