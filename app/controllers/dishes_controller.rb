class DishesController < ApplicationController
  before_action :set_dish, only: [ :edit, :update ]

  def index
    @dishes = current_user.dishes.alive.order(:name)
  end

  def new
    @dish = current_user.dishes.new
  end

  def edit; end

  def create
    @dish = current_user.dishes.new(dish_params)
    if @dish.save
      redirect_to dishes_path, notice: "「#{@dish.name}」を登録しました"
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @dish.update(dish_params)
      redirect_to dishes_path, notice: "「#{@dish.name}」を更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_dish
    @dish = current_user.dishes.find(params[:id])
  end

  def dish_params
    params.require(:dish).permit(:name, :category)
  end
end
