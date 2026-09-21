require "rails_helper"

RSpec.describe "料理マスタ", type: :request do
  let(:user) { create(:user) }

  it "未ログインならログイン画面に飛ぶ" do
    get dishes_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "一覧" do
    before { sign_in user }

    it "0件なら「まだ料理がありません」と出る" do
      get dishes_path
      expect(response.body).to include("まだ料理がありません")
    end

    it "登録済みの料理が一覧に出る" do
      user.dishes.create!(name: "ひじきの煮物", category: "side_dish")
      get dishes_path
      expect(response.body).to include("ひじきの煮物")
    end

    it "論理削除した料理は一覧に出ない" do
      user.dishes.create!(name: "カレー", category: "main_dish", deleted_at: Time.current)
      get dishes_path
      expect(response.body).not_to include("カレー")
    end

    it "他人の料理は一覧に出ない" do
      create(:user).dishes.create!(name: "よその味噌汁", category: "soup")
      get dishes_path
      expect(response.body).not_to include("よその味噌汁")
    end
  end

  describe "登録" do
    before { sign_in user }

    it "登録できて一覧に戻る" do
      post dishes_path, params: { dish: { name: "カレー", category: "main_dish" } }
      expect(response).to redirect_to(dishes_path)
      expect(user.dishes.alive.pluck(:name)).to eq([ "カレー" ])
    end

    it "同じ名前は登録できず、フォームに理由が出る" do
      user.dishes.create!(name: "カレー", category: "main_dish")
      post dishes_path, params: { dish: { name: "カレー", category: "soup" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("エラー")
    end

    it "名前が空なら登録できない" do
      post dishes_path, params: { dish: { name: "", category: "soup" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "編集" do
    before { sign_in user }

    it "編集できて一覧に戻る" do
      dish = user.dishes.create!(name: "カレー", category: "main_dish")
      patch dish_path(dish), params: { dish: { name: "ビーフカレー" } }
      expect(response).to redirect_to(dishes_path)
      expect(dish.reload.name).to eq("ビーフカレー")
    end

    it "他人の料理は編集画面を開けない" do
      other = create(:user).dishes.create!(name: "よその味噌汁", category: "soup")
      # current_user.dishes.find が RecordNotFound を出し、Rails がそれを 404 に変換する
      get edit_dish_path(other)
      expect(response).to have_http_status(:not_found)
    end
  end
end
