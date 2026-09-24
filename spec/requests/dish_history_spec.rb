require "rails_helper"

# #21 料理の詳細＝その料理を出した日の残食率と改善事項（5-B）
RSpec.describe "料理の履歴", type: :request do
  let(:user) { create(:user) }
  let!(:dish) { create(:dish, user: user, name: "ひじきの煮物", category: "side_dish") }

  # この料理を1品目にした献立を作る
  def serve(date, leftovers: nil, note: nil)
    menu = user.menus.build(date_provided: date)
    menu.menu_items.build(dish: dish, portion_size: 20, weight_of_leftovers: leftovers, items_for_improvement: note)
    menu.tap(&:save!)
  end

  before { sign_in user }

  it "出した日が新しい順に並ぶ" do
    old = serve(Date.new(2026, 9, 1))
    recent = serve(Date.new(2026, 9, 30))
    get dish_path(dish)
    expect(response).to have_http_status(:ok)
    expect(response.body.index(menu_path(recent))).to be < response.body.index(menu_path(old))
  end

  it "残食率と改善事項が同じ画面に出る" do
    serve(Date.new(2026, 9, 24), leftovers: 5, note: "味が濃かった。次回は塩分を控える")
    get dish_path(dish)
    expect(response.body).to include("25.0%", "味が濃かった。次回は塩分を控える")
  end

  it "残食が未入力の日は「未入力」" do
    serve(Date.new(2026, 9, 24))
    get dish_path(dish)
    expect(response.body).to include("未入力")
  end

  it "ほかの料理の記録は出ない" do
    other = create(:dish, user: user, name: "カレー")
    menu = user.menus.build(date_provided: Date.new(2026, 9, 24))
    menu.menu_items.build(dish: other, portion_size: 20)
    menu.save!
    get dish_path(dish)
    expect(response.body).not_to include(menu_path(menu))
  end

  it "改善事項に書いたタグは実行されずに文字として出る" do
    serve(Date.new(2026, 9, 24), note: "<script>alert(1)</script>")
    get dish_path(dish)
    expect(response.body).not_to include("<script>alert(1)</script>")
  end

  it "論理削除した料理も、過去の記録は読める" do
    serve(Date.new(2026, 9, 24), leftovers: 5)
    dish.update!(deleted_at: Time.current)
    get dish_path(dish)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("25.0%")
  end

  it "他人の料理は 404" do
    other_dish = create(:dish, user: create(:user))
    get dish_path(other_dish)
    expect(response).to have_http_status(:not_found)
  end
end
