class RemoveObsoleteProjectFactoryFields < ActiveRecord::Migration[8.1]
  def change
    remove_column :projects, :content_strategy, :text
    remove_column :projects, :content_pillars, :json
    remove_column :projects, :content_pillar_weights, :json
    remove_column :projects, :default_delivery_mode, :string
  end
end
