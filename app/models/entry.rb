class Entry < ActiveRecord::Base

  COLUMN_NAMES = [
    "Date",
    "Invoice Number",
    "Customer Name",
    "Maintenance Start",
    "Maintenance Period",
    "Invoiced",
    "Previous Year",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
    "Current Year Total",
    "Following Year Total"
  ]

  EXPORT_COLUMNS = [
    "date",
    "invoice_number",
    "customer_name",
    "maint_start",
    "period",
    "amount_paid",
    "prev_accrual_total",
    "accruals",
    "accrual_total",
    "next_accrual_total"
  ]

  before_save :calculate_end_date

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|

      COLUMN_NAMES.each do |name|
        csv << name
      end

      all.each do |entry|
        EXPORT_COLUMNS.each do |col|
          if col == "accruals"
            entry.accruals.each do |month|
              csv << month
            end
          else
            csv << entry.attributes.values_at(col)
          end
        end
      end
    end
  end

  def self.import(file)
    Entry.delete_all
    CSV.foreach(file.path, headers: true) do |row|
      entry = Entry.create!(row.to_hash)
    end
  end

  def self.accrue_all!(year)
    Entry.all.each do |entry|
      entry.clear_accruals!
      entry.accrue!(year)
    end
  end

  def accrue!(year)
    self.accruals = [0] * 12

    if self.maint_start < self.date
      start_date = self.date
      months_late = (12 * self.date.year + self.date.month) - (12 * self.maint_start.year + self.maint_start.month)
    else
      start_date = self.maint_start
      months_late = 0
    end
    end_month = self.maint_end.month > 12 ? 12 : self.maint_end.month

    monthly = self.amount_paid / self.period
    if start_date.year < year
      num_months_prev = (year * 12 + 1) - (start_date.year * 12 + start_date.month)
      self.prev_accrual_total = num_months_prev * monthly
      start_date = Date.new(year, 1, 1)
    end

    (start_date.month - 1...end_month).each do |month|
      self.accruals[month] = monthly
    end

    unless months_late.zero? || start_date.year != year
      self.accruals[start_date.month - 1] = monthly * months_late
    end


    self.calc_next_year(monthly, year)
    self.accrual_total = self.accruals.sum

    self.save!
  end

  def calc_prev_year(monthly, year)
    num_months_prev = (year * 12 + 1) - (self.maint_start.year * 12 + self.maint_start.month)
    self.prev_accrual_total = num_months_prev * monthly
  end

  def calc_next_year(monthly, year)
    if self.maint_end.year > year
      months_past = (12 * self.maint_end.year + self.maint_end.month - 12 * year + 12)
      self.next_accrual_total = monthly * months_past
    else
      self.next_accrual_total = 0
    end
  end

  def clear_accruals!
    self.next_accrual_total = 0
    self.prev_accrual_total = 0
    self.accrual_total = 0
    self.accruals = []
  end

  private

  def calculate_end_date
    self.maint_end = self.maint_start.advance(months: self.period - 1)
  end
end
