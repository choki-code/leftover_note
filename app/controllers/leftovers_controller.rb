class LeftoversController < ApplicationController
  before_action :set_menu

  def edit
    @menu_items = @menu.menu_items.includes(:dish).order(:id)
  end

  def update
    if @menu.update(leftovers_params)
      redirect_to @menu, notice: "残食を保存しました。"
    else
      @menu_items = @menu.menu_items.includes(:dish).order(:id)
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_menu
    @menu = current_user.menus.find(params[:menu_id])
  end

  def leftovers_params
    params.require(:menu).permit(menu_items_attributes: [ :id, :weight_of_leftovers, :items_for_improvement ])
  end
end
