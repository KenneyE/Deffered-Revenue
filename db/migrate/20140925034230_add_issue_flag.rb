class AddIssueFlag < ActiveRecord::Migration
  def change
    add_column :entries, :issue_flag, :boolean, default: false
  end
end
