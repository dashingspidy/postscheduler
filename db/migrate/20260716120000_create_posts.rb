class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :content, null: false
      t.datetime :scheduled_at
      t.json :platforms, null: false, default: []
      t.json :account_ids, null: false, default: {}
      t.string :status, null: false, default: "draft"
      t.string :zernio_post_id

      t.timestamps
    end

    add_index :posts, :scheduled_at
    add_index :posts, :zernio_post_id, unique: true
  end
end
