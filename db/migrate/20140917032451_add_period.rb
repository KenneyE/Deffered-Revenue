class AddPeriod < ActiveRecord::Migration
  def change
    add_column :entries, :period, :integer
  end
end
