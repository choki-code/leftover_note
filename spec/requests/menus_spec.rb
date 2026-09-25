require "rails_helper"

# #16 献立の新規登録（3-A）と、保存後に着く詳細画面。
# #17 で詳細画面に残食量・残食率・色分け（3-F）を足した
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

  describe "詳細（残食量・残食率・色分け）" do
    before { sign_in user }

    # 境目ちょうどの値で作る: 3/10 = 30%（赤の下限）、1.5/10 = 15%（黄の下限）
    let!(:menu) do
      salad = create(:dish, user: user, name: "サラダ")
      soup  = create(:dish, user: user, name: "スープ")
      create(:menu, user: user, menu_items: [
        build(:menu_item, menu: nil, dish: rice,  portion_size: 10, weight_of_leftovers: 3),
        build(:menu_item, menu: nil, dish: curry, portion_size: 10, weight_of_leftovers: 1.5),
        build(:menu_item, menu: nil, dish: salad, portion_size: 10, weight_of_leftovers: 1),
        build(:menu_item, menu: nil, dish: soup,  portion_size: 10, weight_of_leftovers: nil)
      ])
    end

    it "品目ごとに提供量・残食量・残食率が出る" do
      get menu_path(menu)
      expect(response.body).to include("10.0 kg", "3.0 kg", "30.0%", "15.0%", "10.0%")
    end

    it "30%以上は赤、15%以上は黄、それ未満は緑の行になる" do
      get menu_path(menu)
      assert_select "tr.rate-high td",   text: "ごはん"
      assert_select "tr.rate-middle td", text: "カレー"
      assert_select "tr.rate-low td",    text: "サラダ"
    end

    it "残食が未入力の品は「未入力」と出る" do
      get menu_path(menu)
      assert_select "tr.rate-unrecorded td", text: "未入力"
    end
  end

  describe "一覧（3-C / 3-D）" do
    before { sign_in user }

    # 提供量 20kg の品を、残食の数だけ並べた献立を作る（nil は未入力）
    def create_menu_with(date, leftovers)
      menu = user.menus.build(date_provided: date)
      leftovers.each do |weight|
        menu.menu_items.build(dish: create(:dish, user: user), portion_size: 20, weight_of_leftovers: weight)
      end
      menu.tap(&:save!)
    end

    it "ログイン後の入口（root）が献立一覧" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("献立一覧")
    end

    it "日付の新しい順に並ぶ" do
      old = create_menu_with(Date.new(2026, 9, 1), [ 5 ])
      recent = create_menu_with(Date.new(2026, 9, 30), [ 5 ])
      get menus_path
      expect(response.body.index(menu_path(recent))).to be < response.body.index(menu_path(old))
    end

    it "品数・平均残食率・未入力ありが出る（一部未入力は入力済みの品だけで計算）" do
      create_menu_with(Date.new(2026, 9, 24), [ 5, 5, nil ])
      get menus_path
      expect(response.body).to include("3品", "25.0%", "未入力あり")
    end

    it "全品入力済みの日は「入力済み」" do
      create_menu_with(Date.new(2026, 9, 24), [ 5, 3 ])
      get menus_path
      expect(response.body).to include("20.0%", "入力済み")
      expect(response.body).not_to include("未入力あり")
    end

    it "他人の献立は出ない" do
      other_menu = create(:menu, user: create(:user))
      get menus_path
      expect(response.body).not_to include(menu_path(other_menu))
    end
  end
  describe "編集・更新（#19）" do
    before { sign_in user }

    # ごはん（20kg・残食5kg）とカレー（30kg・未入力）の献立
    let!(:menu) do
      user.menus.build(date_provided: Date.new(2026, 9, 24)).tap do |m|
        m.menu_items.build(dish: rice, portion_size: 20, weight_of_leftovers: 5)
        m.menu_items.build(dish: curry, portion_size: 30)
        m.save!
      end
    end
    let(:rice_item) { menu.menu_items.find_by!(dish: rice) }
    let(:curry_item) { menu.menu_items.find_by!(dish: curry) }

    # フォームから届く形のパラメータ
    def update_params(rows)
      items = rows.each_with_index.to_h { |row, i| [ i.to_s, row ] }
      { menu: { date_provided: menu.date_provided.to_s, menu_items_attributes: items } }
    end

    it "編集画面に既存の品目が id つきで入っている" do
      get edit_menu_path(menu)
      expect(response).to have_http_status(:ok)
      assert_select "input[type=hidden][name$='[id]'][value=?]", rice_item.id.to_s
      assert_select "input[type=hidden][name$='[id]'][value=?]", curry_item.id.to_s
    end

    it "提供量を直すと、品目は増えずに更新され、詳細に戻る" do
      expect {
        patch menu_path(menu), params: update_params([ { id: curry_item.id, portion_size: "25" } ])
      }.not_to change(MenuItem, :count)
      expect(response).to redirect_to(menu_path(menu))
      expect(curry_item.reload.portion_size).to eq(25)
    end

    it "空の行に料理を入れると品目を追加できる" do
      soup = create(:dish, user: user, name: "みそ汁", category: "soup")
      expect {
        patch menu_path(menu), params: update_params([ { dish_id: soup.id, portion_size: "10" } ])
      }.to change(MenuItem, :count).by(1)
      expect(response).to redirect_to(menu_path(menu))
    end

    it "提供量を残食量より下げると 422 で、変わらない（4-D が update でも効く）" do
      patch menu_path(menu), params: update_params([ { id: rice_item.id, portion_size: "3" } ])
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("を超えられません")
      expect(rice_item.reload.portion_size).to eq(20)
    end

    it "料理を付け替えて重複すると 422 で、変わらない" do
      patch menu_path(menu), params: update_params([ { id: curry_item.id, dish_id: rice.id } ])
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("同じ料理を2回選んでいます")
      expect(curry_item.reload.dish).to eq(curry)
    end

    it "論理削除した料理が入っていても、編集画面の選択肢に残る" do
      rice.update!(deleted_at: Time.current)
      get edit_menu_path(menu)
      assert_select "option[value=?]", rice.id.to_s
    end

    # 404 のあとはログインのセッションが保存されないので、1つの it でリクエストは1回だけにする
    it "他人の献立の編集画面は 404" do
      other_menu = create(:menu, user: create(:user))
      get edit_menu_path(other_menu)
      expect(response).to have_http_status(:not_found)
    end

    it "他人の献立は更新できず 404" do
      other_menu = create(:menu, user: create(:user))
      patch menu_path(other_menu), params: { menu: { attendance_count: "1" } }
      expect(response).to have_http_status(:not_found)
      expect(other_menu.reload.attendance_count).to be_nil
    end
  end

  describe "絞り込み（#24）" do
    before { sign_in user }

    let!(:sep1)  { create(:menu, user: user, date_provided: Date.new(2026, 9, 1),  menu_items: [ build(:menu_item, menu: nil, dish: rice) ]) }
    let!(:sep15) { create(:menu, user: user, date_provided: Date.new(2026, 9, 15), menu_items: [ build(:menu_item, menu: nil, dish: rice), build(:menu_item, menu: nil, dish: curry) ]) }
    let!(:sep30) { create(:menu, user: user, date_provided: Date.new(2026, 9, 30), menu_items: [ build(:menu_item, menu: nil, dish: curry) ]) }

    # "/menus/1" が "/menus/15" に含まれてしまわないよう、閉じの " まで見る
    def listed?(menu)
      response.body.include?("href=\"#{menu_path(menu)}\"")
    end

    it "開始日と終了日の両方で、その期間だけ出る" do
      get menus_path(from: "2026-09-10", to: "2026-09-20")
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ false, true, false ])
    end

    it "開始日だけなら、その日以降がすべて出る" do
      get menus_path(from: "2026-09-10")
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ false, true, true ])
    end

    it "終了日だけなら、メッセージを出して日付では絞らない" do
      get menus_path(to: "2026-09-20")
      expect(response.body).to include("開始日も入れてください")
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ true, true, true ])
    end

    it "開始日が終了日より後なら、メッセージを出して日付では絞らない" do
      get menus_path(from: "2026-09-30", to: "2026-09-01")
      expect(response.body).to include("開始日は終了日より前")
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ true, true, true ])
    end

    # includes と joins を混ぜると品目が1品だけ読み込まれる落とし穴の見張り
    it "料理で絞っても、献立の品数は全品のまま" do
      get menus_path(dish_id: curry.id)
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ false, true, true ])
      expect(response.body).to include("2品")
    end

    it "消した料理も選択肢に出て、それで絞り込める" do
      curry.update!(deleted_at: Time.current)
      get menus_path(dish_id: curry.id)
      expect(response.body).to include("カレー（削除済み）")
      expect([ listed?(sep1), listed?(sep15), listed?(sep30) ]).to eq([ false, true, true ])
    end

    it "絞り込んだあとも、入力欄に条件が残る" do
      get menus_path(from: "2026-09-10", to: "2026-09-20")
      expect(response.body).to include('value="2026-09-10"', 'value="2026-09-20"')
    end

    it "日付でない文字が来てもエラー画面にならない" do
      get menus_path(from: "abc")
      expect(response).to have_http_status(:ok)
    end
  end
end
