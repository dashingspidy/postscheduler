class CreateSlideshowImports < ActiveRecord::Migration[8.1]
  def change
    create_table :slideshow_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tiktok_account_id, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_rows, null: false, default: 0
      t.integer :completed_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.text :error_message
      t.timestamps
    end

    create_table :slideshow_items do |t|
      t.references :slideshow_import, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.integer :position, null: false
      t.json :data, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.timestamps
    end

    add_index :slideshow_items, %i[slideshow_import_id position], unique: true
  end
end
