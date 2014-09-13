class EntriesController < ApplicationController
  def index
    @entries = Entry.all()
    respond_to do | format |
      format.html
      format.csv { render text: @entries.to_csv }
      # format.xls { send_data @entries.to_csv(col_sep: "\t")}
    end
  end

  def import
    Entry.import(params[:file])
    flash[:notice] = ["Entries imported"]
    redirect_to root_url
  end

  def clear
    Entry.delete_all
    redirect_to root_url
  end
end