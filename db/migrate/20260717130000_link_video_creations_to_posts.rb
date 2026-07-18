class LinkVideoCreationsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :video_creations, :post, foreign_key: true
  end
end
