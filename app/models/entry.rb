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

      # start_month = entry.maint_start.month
      # end_month = entry.maint_end.month
      #
      # months_late = entry.date.month - start_month
      # start_month += months_late if months_late > 0
      #
      # num_months = end_month - start_month
      # monthly = entry.amount_paid / num_months
      #
      # entry.accruals[start_month] = monthly * (months_late + 1)
      #
      # (start_month + 1..entry.maint_end.month).each do |month|
      #   entry.accruals[month] = monthly
      # end

      entry.accrual_total = entry.accruals.sum
      #
      # if start_month < year
      #   entry.calc_prev_year(monthly, year)
      # end

      entry.save!
    end
  end

  def calc_prev_year(monthly, year)
    num_months_prev = (year * 12 + 1) - (self.maint_start.year * 12 + self.maint_start.month)
    self.prev_accrual_total = num_months_prev * monthly
  end

end
