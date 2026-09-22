require "rails_helper"

# #12 学校情報の登録（新規登録）・編集（devise のアカウント編集）・見出し表示
RSpec.describe "学校情報", type: :request do
  let(:sign_up_params) do
    {
      email: "new@example.com", password: "password", password_confirmation: "password",
      school_name: "ひまわり小学校", academic_year: "2026", current_enrollment: 320
    }
  end

  describe "新規登録" do
    # devise の Strong Parameters に3項目を足さないと、黙って捨てられて NOT NULL で落ちる
    it "学校情報つきで登録できる" do
      expect {
        post user_registration_path, params: { user: sign_up_params }
      }.to change(User, :count).by(1)
      expect(User.last.school_name).to eq("ひまわり小学校")
    end

    it "学校名が空なら登録できない" do
      expect {
        post user_registration_path, params: { user: sign_up_params.merge(school_name: "") }
      }.not_to change(User, :count)
    end
  end

  describe "アカウント編集" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "現在のパスワードを入れれば学校名を直せる" do
      patch user_registration_path, params: { user: { school_name: "あさがお小学校", current_password: "password" } }
      expect(user.reload.school_name).to eq("あさがお小学校")
    end

    # devise の既定の動き。パスワード無しで書き換えられないことを仕様として残す
    it "現在のパスワードが無ければ直せない" do
      patch user_registration_path, params: { user: { school_name: "あさがお小学校" } }
      expect(user.reload.school_name).not_to eq("あさがお小学校")
    end
  end

  describe "見出し" do
    it "ログイン後の画面に学校名・年度・全校児童数が出る" do
      sign_in create(:user, school_name: "ひまわり小学校", academic_year: "2026", current_enrollment: 320)
      get dishes_path
      expect(response.body).to include("ひまわり小学校 2026年度（全校児童数 320人）")
    end
  end
end
