Rails.application.routes.draw do
  devise_for :users

  root "dishes#index"

  resources :dishes, except: %i[show] do
    get :confirm_destroy, on: :member   # 2-D 削除前の確認画面
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
