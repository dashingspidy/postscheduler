class ReplaceSlideshowImportsWithSlideshows < ActiveRecord::Migration[8.1]
  def up
    rename_table :slideshow_imports, :slideshows
    rename_table :slideshow_import_targets, :slideshow_targets
    rename_column :slideshow_targets, :slideshow_import_id, :slideshow_id

    add_column :slideshows, :data, :json, null: false, default: {}
    add_reference :slideshows, :post, foreign_key: true

    execute <<~SQL
      UPDATE slideshows
      SET data = COALESCE((SELECT data FROM slideshow_items WHERE slideshow_items.slideshow_import_id = slideshows.id ORDER BY position LIMIT 1), '{}'),
          post_id = (SELECT post_id FROM slideshow_items WHERE slideshow_items.slideshow_import_id = slideshows.id ORDER BY position LIMIT 1)
    SQL

    drop_table :slideshow_items
    remove_column :slideshows, :tiktok_account_id
    remove_columns :slideshows, :total_rows, :completed_rows, :failed_rows
  end

  def down
    add_column :slideshows, :total_rows, :integer, null: false, default: 0
    add_column :slideshows, :completed_rows, :integer, null: false, default: 0
    add_column :slideshows, :failed_rows, :integer, null: false, default: 0
    add_column :slideshows, :tiktok_account_id, :string
    create_table :slideshow_items do |t|
      t.references :slideshow_import, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.integer :position, null: false
      t.json :data, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.timestamps
    end
    remove_reference :slideshows, :post, foreign_key: true
    remove_column :slideshows, :data
    rename_column :slideshow_targets, :slideshow_id, :slideshow_import_id
    rename_table :slideshow_targets, :slideshow_import_targets
    rename_table :slideshows, :slideshow_imports
  end
end
