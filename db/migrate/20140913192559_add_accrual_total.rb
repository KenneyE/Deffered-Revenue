class AddAccrualTotal < ActiveRecord::Migration
  def change
    add_column :entries, :prev_accrual_total, :decimal
    add_column :entries, :accrual_total, :decimal
    add_column :entries, :next_accrual_total, :decimal
  end
end
