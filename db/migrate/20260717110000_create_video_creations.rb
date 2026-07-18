class CreateVideoCreations < ActiveRecord::Migration[8.1]
  def change
    create_table :video_creations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :call_to_action, null: false
      t.text :error_message

      t.timestamps
    end
  end
end
