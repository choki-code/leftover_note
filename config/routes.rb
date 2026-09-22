Rails.application.routes.draw do
  devise_for :users, skip: :registrations
  # 退会（DELETE /users）だけ塞ぐ。ユーザーを消すと料理・献立・残食の記録まで消えるため
  devise_scope :user do
    resource :registration,
            only: %i[new create edit update],
            path: "users",
            path_names: { new: "sign_up" },
            controller: "devise/registrations",
            as: :user_registration do
      get :cancel
    end
  end

  root "dishes#index"

  resources :dishes, except: %i[show] do
    get :confirm_destroy, on: :member   # 2-D 削除前の確認画面
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
