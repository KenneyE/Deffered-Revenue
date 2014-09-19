class Entry < ActiveRecord::Base

  before_save :calculate_end_date

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
      entry.accruals = [0] * 12

      if entry.maint_start < entry.date
        start_date = entry.date
        months_late = (12 * entry.date.year + entry.date.month) - (12 * entry.maint_start.year + entry.maint_start.month)
      else
        start_date = entry.maint_start
        months_late = 0
      end
      entry_date = entry.maint_start.advance(month: entry.period - 1)
      end_month = entry_date.month > 12 ? 12 : entry_date.month

      monthly = entry.amount_paid / entry.period
      if start_date.year < year
        num_months_prev = (year * 12 + 1) - (start_date.year * 12 + start_date.month)
        entry.prev_accrual_total = num_months_prev * monthly
        start_date = Date.new(year, 1, 1)
      end

      (start_date.month - 1...end_month).each do |month|
        entry.accruals[month] = monthly
      end

      unless months_late.zero?
        entry.accruals[start_date.month - 1] = monthly * months_late
      end


      entry.calc_next_year(monthly, year)
      entry.accrual_total = entry.accruals.sum

      entry.save!
    end
  end

  def calc_prev_year(monthly, year)
    num_months_prev = (year * 12 + 1) - (self.maint_start.year * 12 + self.maint_start.month)
    self.prev_accrual_total = num_months_prev * monthly
  end

  def calc_next_year(monthly, year)
    if self.maint_end.year > year
      months_diff = (12 * self.maint_end.year + self.maint_end.month - 12 * year + 12)
      self.next_accrual_total = monthly * months_diff
    else
      self.next_accrual_total = 0
    end
  end

  private

  def calculate_end_date
    self.maint_end = self.maint_start.advance(months: self.period)
  end
end
