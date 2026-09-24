class MenusController < ApplicationController
  INITIAL_ITEM_ROWS = 5
  before_action :set_menu, only: %i[show edit update]

  def index
    @menus = current_user.menus.recent_first.includes(:menu_items)
  end

  def new
    @menu = current_user.menus.new
    prepare_form
  end

  def show
    @menu_items = @menu.menu_items.includes(:dish).order(:id)
  end

  def edit
    prepare_form
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

  def update
    if @menu.update(menu_params)
      redirect_to @menu, notice: "献立を更新しました。"
    else
      prepare_form
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_menu
    @menu = current_user.menus.find(params[:id])
  end

  def menu_params
    params.require(:menu).permit(:date_provided, :attendance_count, :excluded_from_stats, :exclusion_reason,
    menu_items_attributes: [ :id, :dish_id, :portion_size ])
  end

  def prepare_form
    (INITIAL_ITEM_ROWS - @menu.menu_items.size).times { @menu.menu_items.build }
    used_ids = @menu.menu_items.filter_map(&:dish_id)
    @dishes = current_user.dishes.alive.or(current_user.dishes.where(id: used_ids)).order(:name)
  end
end
