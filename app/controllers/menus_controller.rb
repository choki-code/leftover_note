class MenusController < ApplicationController
  INITIAL_ITEM_ROWS = 5
  before_action :set_menu, only: [ :show ]

  def new
    @menu = current_user.menus.new
    prepare_form
  end

  def show
    @menu_items = @menu.menu_items.includes(:dish).order(:id)
  end

  def create
    @menu = current_user.menus.new(menu_params)
    if @menu.save
      redirect_to @menu, notice: "献立を登録しました。"
    else
      prepare_form
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_menu
    @menu = current_user.menus.find(params[:id])
  end

  def menu_params
    params.require(:menu).permit(:date_provided, :attendance_count,
    menu_items_attributes: [ :dish_id, :portion_size ])
  end

  def prepare_form
    (INITIAL_ITEM_ROWS - @menu.menu_items.size).times { @menu.menu_items.build }
    @dishes = current_user.dishes.alive.order(:name)
  end
end
