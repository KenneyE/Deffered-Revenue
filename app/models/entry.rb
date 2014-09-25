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
  # before_save :verify_presence_of_attributes
  # validates :date, :amount_paid, :maint_start, :period, presence: true

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|

      csv << COLUMN_NAMES

      all.each do |entry|
        new_line = entry.attributes.values_at(*EXPORT_COLUMNS[0..6]) +
        entry.accruals +
        entry.attributes.values_at(*EXPORT_COLUMNS[8..9])
        csv << new_line
      end
    end
  end

  def self.import(file)
    Entry.delete_all
    CSV.foreach(file.path, headers: true) do |row|
      hashed_row = row.to_hash
      entry = Entry.new(hashed_row)

      if hashed_row["date"] && hashed_row["maint_start"] && hashed_row["amount_paid"]
        entry.date = Date.strptime(hashed_row["date"], '%m/%d/%Y')
        entry.maint_start = Date.strptime(hashed_row["maint_start"], '%m/%d/%y')
        entry.amount_paid = hashed_row["amount_paid"].delete("$\,")
      else
        entry.issue_flag = true
      end

      entry.save
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

  def verify_presence_of_attributes
    self.issue_flag = self.date &&
    self.maint_start &&
    self.period &&
    self.amount_paid
  end
end
