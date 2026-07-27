class AddContentPillarWeightsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :content_pillar_weights, :json, null: false, default: {}
  end
end
