class AddAccountContentFactories < ActiveRecord::Migration[8.1]
  def change
    add_column :zernio_accounts, :content_strategy, :text
    add_column :zernio_accounts, :content_pillars, :json, null: false, default: []
    add_column :zernio_accounts, :content_pillar_weights, :json, null: false, default: {}
    add_column :zernio_accounts, :factory_enabled, :boolean, null: false, default: true
    add_column :zernio_accounts, :factory_posts_per_day, :integer, null: false, default: 10

    add_reference :content_topics, :zernio_account, foreign_key: true
    add_column :content_topics, :daily_slot, :integer, null: false, default: 1
    remove_index :content_topics, name: :index_content_topics_on_project_id_and_scheduled_for
    add_index :content_topics, %i[zernio_account_id scheduled_for daily_slot], unique: true, name: :index_content_topics_on_account_date_and_slot

    add_reference :slideshows, :zernio_account, foreign_key: true
    add_column :slideshows, :factory_slot, :integer, null: false, default: 1
    remove_index :slideshows, name: :index_slideshows_on_project_id_and_factory_date
    add_index :slideshows, %i[zernio_account_id factory_date factory_slot], unique: true, where: "factory_date IS NOT NULL", name: :index_slideshows_on_account_date_and_slot
  end
end
