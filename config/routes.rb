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

  root "menus#index"

  resources :dishes, except: %i[show] do
    get :confirm_destroy, on: :member   # 2-D 削除前の確認画面
  end

  # 3-A 献立の登録 / 3-C 一覧 / 3-F 詳細（編集・削除は #19 で足す）
  resources :menus, only: %i[index new create show] do
    resource :leftovers, only: %i[edit update]   # 4-A 残食の入力（献立ごと）
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
