require "rails_helper"

# #23 集計対象外の献立（3-G / 3-H）
RSpec.describe "集計対象外の献立", type: :request do
  let(:user) { create(:user) }
  let!(:dish) { create(:dish, user: user, name: "カレー") }

  # 提供量 20kg・残食 5kg（25.0%）の献立
  def create_menu(excluded: false, reason: nil)
    menu = user.menus.build(date_provided: Date.new(2026, 9, 24), excluded_from_stats: excluded, exclusion_reason: reason)
    menu.menu_items.build(dish: dish, portion_size: 20, weight_of_leftovers: 5)
    menu.tap(&:save!)
  end

  before { sign_in user }

  it "チェックして理由があれば対象外にでき、詳細に理由が出る" do
    menu = create_menu
    patch menu_path(menu), params: { menu: { excluded_from_stats: "1", exclusion_reason: "学級閉鎖" } }
    expect(response).to redirect_to(menu_path(menu))
    expect(menu.reload).to be_excluded_from_stats
    follow_redirect!
    expect(response.body).to include("対象外", "学級閉鎖")
  end

  it "チェックして理由が空なら 422 で、対象外にならない（3-G）" do
    menu = create_menu
    patch menu_path(menu), params: { menu: { excluded_from_stats: "1", exclusion_reason: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("対象外の理由を入力してください")
    expect(menu.reload).not_to be_excluded_from_stats
  end

  it "新規登録でも対象外にできる" do
    post menus_path, params: { menu: { date_provided: "2026-09-25", excluded_from_stats: "1", exclusion_reason: "運動会",
      menu_items_attributes: { "0" => { dish_id: dish.id, portion_size: "20" } } } }
    expect(Menu.last).to be_excluded_from_stats
  end

  it "除外した献立も一覧に残食率つきで残り、「対象外」と分かる（3-H）" do
    menu = create_menu(excluded: true, reason: "学級閉鎖")
    get menus_path
    expect(response.body).to include(menu_path(menu), "25.0%", "対象外")
  end

  it "料理の履歴でも、対象外の日だと分かる" do
    create_menu(excluded: true, reason: "学級閉鎖")
    get dish_path(dish)
    expect(response.body).to include("対象外")
  end
end
