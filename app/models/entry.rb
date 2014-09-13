class Entry < ActiveRecord::Base


  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << Entry.column_names
      all.each do |entry|
        csv << entry.attributes.values_at(*column_names)
      end
    end
  end

  def self.import(file)
    Entry.delete_all
    CSV.foreach(file.path, headers: true) do |row|
      Entry.create!(row.to_hash)
    end
  end

  def accrue

  end

  def calc_first_month

  end

  def calculate_monthly
    num_months = self.maint_end.month - self.maint_start.month
    monthly = self.amount_paid / num_months
    (self.maint_start.month..self.maint_end.month).each do |month|
      self.accruals[month] = monthly
    end
  end

end
