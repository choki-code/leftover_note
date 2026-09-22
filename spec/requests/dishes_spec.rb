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

    it "登録済みの料理が、区分の日本語つきで一覧に出る" do
      user.dishes.create!(name: "ひじきの煮物", category: "side_dish")
      get dishes_path
      expect(response.body).to include("ひじきの煮物")
      expect(response.body).to include("副菜")
      expect(response.body).not_to include("side_dish")
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

    it "同じ名前は登録できず、フォームに日本語で理由が出る" do
      user.dishes.create!(name: "カレー", category: "main_dish")
      post dishes_path, params: { dish: { name: "カレー", category: "soup" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("入力に1件の誤りがあります")
      expect(response.body).to include("料理名はすでに登録されています")
    end

    it "名前が空なら登録できない" do
      post dishes_path, params: { dish: { name: "", category: "soup" } }
      expect(response).to have_http_status(:unprocessable_content)
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

  describe "削除" do
    before { sign_in user }

    let(:dish) { user.dishes.create!(name: "カレー", category: "main_dish") }

    def use_in_menu(dish)
      menu = user.menus.build(date_provided: Date.new(2026, 9, 14))
      menu.menu_items.build(dish: dish, portion_size: 20.0)
      menu.save!
    end

    # 2-D: いきなり消さず、必ず確認画面を挟む
    it "確認画面に料理名が出る" do
      get delete_dish_path(dish)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("カレー")
    end

    # 2-F: 消せない理由は例外（500）ではなく、確認画面の文言で伝える
    it "献立で使われている料理は、確認画面に消せない理由が出る" do
      use_in_menu(dish)
      get delete_dish_path(dish)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("献立の記録に使われているため削除できません")
    end

    it "削除すると一覧に戻り、一覧から消えるが、行は残る" do
      delete dish_path(dish)
      expect(response).to redirect_to(dishes_path)
      follow_redirect!
      expect(response.body).not_to include("<td>カレー</td>")
      expect(dish.reload.deleted_at).to be_present
    end

    it "献立で使われている料理は、DELETE を送っても消えない" do
      use_in_menu(dish)
      delete dish_path(dish)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("献立の記録に使われているため削除できません")
      expect(dish.reload.deleted_at).to be_nil
    end

    # 認可: URL の id を書き換えても他人の料理には触れない
    it "他人の料理の確認画面は開けない" do
      other = create(:user).dishes.create!(name: "よその味噌汁", category: "soup")
      get delete_dish_path(other)
      expect(response).to have_http_status(:not_found)
    end

    it "他人の料理は削除できない" do
      other = create(:user).dishes.create!(name: "よその味噌汁", category: "soup")
      delete dish_path(other)
      expect(response).to have_http_status(:not_found)
      expect(other.reload.deleted_at).to be_nil
    end
  end
end
