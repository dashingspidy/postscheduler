class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :tiktok_account_id, null: false
      t.json :style, null: false, default: {}
      t.timestamps
    end

    add_reference :slideshow_imports, :project, foreign_key: true
    add_reference :posts, :project, foreign_key: true
  end
end
