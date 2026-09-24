require "rails_helper"

# #19 献立の品目を1品ずつ削除する（誤記録の訂正なので物理削除）
RSpec.describe "品目の削除", type: :request do
  let(:user) { create(:user) }

  # ごはん（残食5kg）とカレー（未入力）の2品の献立
  let!(:menu) do
    user.menus.build(date_provided: Date.new(2026, 9, 24)).tap do |m|
      m.menu_items.build(dish: create(:dish, user: user, name: "ごはん"), portion_size: 20, weight_of_leftovers: 5)
      m.menu_items.build(dish: create(:dish, user: user, name: "カレー"), portion_size: 30)
      m.save!
    end
  end
  let(:item) { menu.menu_items.order(:id).first }

  it "未ログインならログイン画面に飛ぶ" do
    delete menu_menu_item_path(menu, item)
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "削除" do
    before { sign_in user }

    it "品目が消え、同じ献立の詳細に 303 で戻る" do
      expect { delete menu_menu_item_path(menu, item) }.to change(MenuItem, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(menu_path(menu))
    end

    it "最後の1品は消せず、理由が出る" do
      menu.menu_items.order(:id).last.destroy!
      expect { delete menu_menu_item_path(menu, item) }.not_to change(MenuItem, :count)
      follow_redirect!
      expect(response.body).to include("献立には料理を1品以上残してください。")
    end

    it "他人の献立の品目は消せず 404" do
      other_menu = create(:menu, user: create(:user))
      other_item = other_menu.menu_items.first
      expect { delete menu_menu_item_path(other_menu, other_item) }.not_to change(MenuItem, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "別の献立の品目 id を差し込んでも消せず 404" do
      other_item = create(:menu, user: user).menu_items.first
      expect { delete menu_menu_item_path(menu, other_item) }.not_to change(MenuItem, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "詳細画面の削除ボタン" do
    before { sign_in user }

    it "残食がある品目だけ「残食記録と改善事項も消えます」と確認が出る" do
      get menu_path(menu)
      expect(response.body).to include("「ごはん」の残食記録と改善事項も消えます。削除しますか？")
      expect(response.body).to include("「カレー」を献立から削除しますか？")
    end

    it "1品だけの献立には削除ボタンが出ない" do
      menu.menu_items.order(:id).last.destroy!
      get menu_path(menu)
      expect(response.body).not_to include(menu_menu_item_path(menu, item))
    end
  end
end
