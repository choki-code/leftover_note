class AnalysesController < ApplicationController
  def show
    today = Date.current

    if today.month < 4
      fiscal_year_start = Date.new(today.year - 1, 4, 1)
    else
      fiscal_year_start = Date.new(today.year, 4, 1)
    end

    fiscal_year_end = fiscal_year_start.next_year - 1.day

    @ranking = MenuItem.ranking_for(
      current_user,
      fiscal_year_start..fiscal_year_end
    )
    @yearly_rates = MenuItem.yearly_rates_for(current_user)
  end
end
