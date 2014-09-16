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
    end
  end

  def self.accrue!(year)
    Entry.all.each do |entry|

      if self.maint_start.year < year
        entry.calc_prev_year
      end
      entry.accruals = [0] * 12
      start_month = entry.maint_start.month
      end_month = entry.maint_end.month

      months_late = entry.date.month - start_month
      start_month += months_late if months_late > 0

      num_months = end_month - start_month
      monthly = entry.amount_paid / num_months

      entry.accruals[start_month] = monthly * (months_late + 1)

      (start_month + 1..entry.maint_end.month).each do |month|
        entry.accruals[month] = monthly
      end

      entry.accrual_total = entry.accruals.sum

      entry.save!
    end
  end

  def calc_monthly
    self.amount_paid / self.period
  end

  def calc_prev_year(monthly)
    num_months_into_prev_year = 13 - self.maint_start.month
    self.prev_accrual_total = num_months_into_prev_year * monthly
  end

end
