class MenuItemsController < ApplicationController
  before_action :set_menu

  def destroy
    item = @menu.menu_items.find(params[:id])

    if @menu.menu_items.size <= 1
      redirect_to @menu, alert: "献立には料理を1品以上残してください。", status: :see_other
    else
      item.destroy!
      redirect_to @menu, notice: "「#{item.dish.name}」を献立から削除しました。", status: :see_other
    end
  end

  private

  def set_menu
    @menu = current_user.menus.find(params[:menu_id])
  end
end
