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

      start_date = entry.maint_start > entry.date ? entry.maint_start : entry.date
      end_month = entry.maint_end.year > year ? 12 : entry.maint_end.month

      monthly = entry.amount_paid / entry.period
      if start_date.year < year
        entry.calc_prev_year(monthly, year)
        start_date = Date.new(year, 1, 1)
      elsif start_date.year == year
        (start_date.month - 1...end_month).each do |month|
          entry.accruals[month] = monthly
        end
        if entry.date.month > entry.maint_start.month
          entry.accruals[start_date.month - 1] = monthly * (entry.date.month - entry.maint_start.month + 1)
        end
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
    self.maint_end = self.maint_start.advance(months: period)
  end


end
