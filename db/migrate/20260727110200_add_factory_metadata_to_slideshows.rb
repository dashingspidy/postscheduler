class AddFactoryMetadataToSlideshows < ActiveRecord::Migration[8.1]
  def change
    add_reference :slideshows, :content_topic, foreign_key: true
    add_column :slideshows, :factory_date, :date
    add_index :slideshows, %i[project_id factory_date], unique: true, where: "factory_date IS NOT NULL"
  end
end
