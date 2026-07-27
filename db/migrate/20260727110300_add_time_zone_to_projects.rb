class AddTimeZoneToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :time_zone, :string, null: false, default: "Europe/Brussels"
  end
end
