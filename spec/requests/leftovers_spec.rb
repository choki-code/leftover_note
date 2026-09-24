require "rails_helper"

# #18 残食量と改善事項の入力（4-A / 4-B / 4-C / 4-D）。
# 残食専用の入口なので、料理・提供量はここからは変えられない
RSpec.describe "残食の入力", type: :request do
  let(:user) { create(:user) }
  # factory が1品（提供量 20.0kg・残食は空）を自動でつける
  let!(:menu) { create(:menu, user: user) }
  let(:item) { menu.menu_items.first }

  # フォームから届く形のパラメータ
  def leftovers_params(attrs)
    { menu: { menu_items_attributes: { "0" => { id: item.id }.merge(attrs) } } }
  end

  it "未ログインならログイン画面に飛ぶ" do
    get edit_menu_leftovers_path(menu)
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "入力画面" do
    before { sign_in user }

    it "品目の料理名と、改善事項のプレースホルダが出る（4-E）" do
      get edit_menu_leftovers_path(menu)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(item.dish.name)
      expect(response.body).to include("例：味が濃かった。次回は塩分を控える")
    end

    it "料理と提供量は入力欄にしない" do
      get edit_menu_leftovers_path(menu)
      expect(response.body).not_to include("[dish_id]")
      expect(response.body).not_to include("[portion_size]")
    end

    it "他人の献立は 404" do
      other_menu = create(:menu, user: create(:user))
      get edit_menu_leftovers_path(other_menu)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "保存" do
    before { sign_in user }

    it "残食量と改善事項が保存され、同じ献立の詳細に戻って残食率が出る" do
      patch menu_leftovers_path(menu),
            params: leftovers_params(weight_of_leftovers: "5", items_for_improvement: "味が濃かった")
      expect(response).to redirect_to(menu_path(menu))
      expect(item.reload.weight_of_leftovers).to eq(5)
      expect(item.items_for_improvement).to eq("味が濃かった")

      follow_redirect!
      expect(response.body).to include("25.0%") # 5 ÷ 20
    end

    it "残食が空のままでも保存できる（4-C）" do
      patch menu_leftovers_path(menu), params: leftovers_params(weight_of_leftovers: "")
      expect(response).to redirect_to(menu_path(menu))
      expect(item.reload.weight_of_leftovers).to be_nil
    end

    it "提供量を超える残食は 422 で、日本語の理由が出て保存されない（4-D）" do
      patch menu_leftovers_path(menu), params: leftovers_params(weight_of_leftovers: "25")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("残食量(kg)は提供量（20.0kg）を超えられません")
      expect(item.reload.weight_of_leftovers).to be_nil
    end

    it "料理と提供量を送りつけられても変わらない" do
      other_dish = create(:dish, user: user)
      patch menu_leftovers_path(menu),
            params: leftovers_params(weight_of_leftovers: "5", dish_id: other_dish.id, portion_size: "99")
      item.reload
      expect(item.dish_id).not_to eq(other_dish.id)
      expect(item.portion_size).to eq(20)
    end

    it "他人の献立には書き込めず 404" do
      other_menu = create(:menu, user: create(:user))
      other_item = other_menu.menu_items.first
      patch menu_leftovers_path(other_menu),
            params: { menu: { menu_items_attributes: { "0" => { id: other_item.id, weight_of_leftovers: "5" } } } }
      expect(response).to have_http_status(:not_found)
      expect(other_item.reload.weight_of_leftovers).to be_nil
    end

    it "別の献立の品目 id を差し込んでも書き込めず 404" do
      other_item = create(:menu, user: user).menu_items.first
      patch menu_leftovers_path(menu),
            params: { menu: { menu_items_attributes: { "0" => { id: other_item.id, weight_of_leftovers: "5" } } } }
      expect(response).to have_http_status(:not_found)
      expect(other_item.reload.weight_of_leftovers).to be_nil
    end
  end
end
