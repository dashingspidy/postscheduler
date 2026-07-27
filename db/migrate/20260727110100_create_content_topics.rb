class CreateContentTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :content_topics do |t|
      t.references :project, null: false, foreign_key: true
      t.references :slideshow, foreign_key: true
      t.string :pillar, null: false
      t.string :title
      t.date :scheduled_for, null: false
      t.string :status, null: false, default: "planned"
      t.timestamps
    end

    add_index :content_topics, %i[project_id scheduled_for], unique: true
  end
end
