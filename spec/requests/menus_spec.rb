require "rails_helper"

# #16 献立の新規登録（3-A）と、保存後に着く最小の詳細画面。
# 残食量・残食率・色分けは #17 で詳細画面に足す
RSpec.describe "献立", type: :request do
  let(:user) { create(:user) }
  let!(:rice)  { create(:dish, user: user, name: "ごはん", category: "staple_food") }
  let!(:curry) { create(:dish, user: user, name: "カレー", category: "main_dish") }

  # フォームから届く形のパラメータ。空の行（料理も提供量も空）は無視される前提
  def menu_params(date: "2026-09-24", rows: nil)
    rows ||= [
      { dish_id: rice.id, portion_size: "20.5" },
      { dish_id: curry.id, portion_size: "30" },
      { dish_id: "", portion_size: "" }
    ]
    items = rows.each_with_index.to_h { |row, i| [ i.to_s, row ] }
    { menu: { date_provided: date, attendance_count: "300", menu_items_attributes: items } }
  end

  it "未ログインならログイン画面に飛ぶ" do
    get new_menu_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "新規登録画面" do
    before { sign_in user }

    # INITIAL_ITEM_ROWS = 5（Issue #16）
    it "品目の入力行が5行ある" do
      get new_menu_path
      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/menu\[menu_items_attributes\]\[\d+\]\[dish_id\]/).uniq.size).to eq(5)
    end

    # 料理は手入力させず、自分のマスタ（削除済みを除く）から選ばせる
    it "料理の選択肢は自分の料理だけで、削除済みは出ない" do
      create(:dish, user: user, name: "消した汁物", category: "soup", deleted_at: Time.current)
      create(:dish, user: create(:user), name: "よその煮物", category: "side_dish")
      get new_menu_path
      expect(response.body).to include("ごはん", "カレー")
      expect(response.body).not_to include("消した汁物")
      expect(response.body).not_to include("よその煮物")
    end
  end

  describe "登録" do
    before { sign_in user }

    it "複数品まとめて登録でき、空の行は無視され、詳細へ移る" do
      expect {
        post menus_path, params: menu_params
      }.to change(Menu, :count).by(1).and change(MenuItem, :count).by(2)
      expect(response).to redirect_to(menu_path(Menu.last))
    end

    it "同じ日の二重登録は 422 でフォームに戻り、理由が上にまとめて出る" do
      post menus_path, params: menu_params
      expect {
        post menus_path, params: menu_params
      }.not_to change(Menu, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("同じ日の献立は1件だけです")
    end

    it "同じ料理を2行選ぶと 422 で理由が出る" do
      rows = [ { dish_id: rice.id, portion_size: "20" }, { dish_id: rice.id, portion_size: "10" } ]
      expect {
        post menus_path, params: menu_params(rows: rows)
      }.not_to change(Menu, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("同じ料理を2回選んでいます")
    end

    it "品目が1つも無ければ 422 で理由が出る" do
      rows = [ { dish_id: "", portion_size: "" } ]
      post menus_path, params: menu_params(rows: rows)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("料理を1品以上登録してください")
    end

    # 認可: Strong Parameters は dish_id の中身が誰のものかは見ない。#15 の検証が最後の砦
    it "他人の料理の id を送られても登録されない" do
      other_dish = create(:dish, user: create(:user), name: "よその煮物", category: "side_dish")
      rows = [ { dish_id: other_dish.id, portion_size: "20" } ]
      expect {
        post menus_path, params: menu_params(rows: rows)
      }.not_to change(Menu, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    # Mass Assignment: 許可していない user_id を送っても、自分の献立として保存される
    it "user_id を送っても無視され、ログイン中のユーザーの献立になる" do
      other = create(:user)
      params = menu_params
      params[:menu][:user_id] = other.id
      post menus_path, params: params
      expect(Menu.last.user).to eq(user)
    end
  end

  describe "詳細（最小）" do
    before { sign_in user }

    it "登録した品目の料理名と提供量が出る" do
      post menus_path, params: menu_params
      get menu_path(Menu.last)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ごはん", "カレー", "20.5")
    end

    it "他人の献立は開けない" do
      other_menu = create(:menu, user: create(:user))
      get menu_path(other_menu)
      expect(response).to have_http_status(:not_found)
    end
  end
end
