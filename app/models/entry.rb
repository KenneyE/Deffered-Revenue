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
      entry = Entry.create!(row.to_hash)
      entry.accrue!
    end
  end

  def accrue!
    self.accruals = [0] * 12
    start_month = self.maint_start.month
    end_month = self.maint_end.month

    months_late = self.date.month - start_month
    start_month += months_late if months_late > 0

    num_months = end_month - start_month
    monthly = self.amount_paid / num_months

    self.accruals[start_month] = monthly * (months_late + 1)

    (start_month + 1..self.maint_end.month).each do |month|
      self.accruals[month] = monthly
    end

    self.save!
  end

end
