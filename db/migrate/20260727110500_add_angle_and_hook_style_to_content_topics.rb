class AddAngleAndHookStyleToContentTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :content_topics, :angle, :string
    add_column :content_topics, :hook_style, :string
    add_index :content_topics, %i[project_id pillar angle]
  end
end
