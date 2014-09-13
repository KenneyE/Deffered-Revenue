class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.date :date
      t.integer :invoice_number
      t.string :customer_name
      t.date :maint_start
      t.date :maint_end
      t.decimal :amount_paid

      t.timestamps
    end
  end
end
