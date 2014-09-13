class AddAccruals < ActiveRecord::Migration
  def change
    add_column :entries, :accruals, :text, array: true
  end
end
