class AddSlideshowAiPrompt < ActiveRecord::Migration[8.1]
  def change
    add_column :slideshow_imports, :prompt, :text
    add_column :slideshow_imports, :slide_count, :integer, null: false, default: 5
  end
end
