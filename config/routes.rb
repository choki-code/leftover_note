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

  # 3-A 登録 / 3-C 一覧 / 3-F 詳細 / 品目の編集（#19）
  resources :menus, only: %i[index new create show edit update] do
    resource :leftovers, only: %i[edit update]   # 4-A 残食の入力（献立ごと）
    resources :menu_items, only: %i[destroy]     # #19 品目を1品ずつ削除
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
