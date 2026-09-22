require "rails_helper"

# #12 学校情報（1-C）の仕様
RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe "学校名" do
    it "無ければ保存できない" do
      user.school_name = ""
      expect(user).not_to be_valid
      expect(user.errors[:school_name]).to be_present
    end

    it "100文字までは通る" do
      user.school_name = "あ" * 100
      expect(user).to be_valid
    end

    it "101文字は通らない" do
      user.school_name = "あ" * 101
      expect(user).not_to be_valid
    end
  end

  describe "年度" do
    it "無ければ保存できない" do
      user.academic_year = ""
      expect(user).not_to be_valid
      expect(user.errors[:academic_year]).to be_present
    end
  end

  describe "全校児童数" do
    it "無ければ保存できない" do
      user.current_enrollment = nil
      expect(user).not_to be_valid
    end

    # 境界値: 1 と 10,000 は通り、その外側は通らない
    it "1 は通る" do
      user.current_enrollment = 1
      expect(user).to be_valid
    end

    it "0 は通らない" do
      user.current_enrollment = 0
      expect(user).not_to be_valid
    end

    it "10,000 は通る" do
      user.current_enrollment = 10_000
      expect(user).to be_valid
    end

    it "10,001 は通らない" do
      user.current_enrollment = 10_001
      expect(user).not_to be_valid
    end

    it "小数は通らない" do
      user.current_enrollment = 320.5
      expect(user).not_to be_valid
    end
  end

  describe "#heading_label" do
    # Issue #12 の例「○○小学校 2026年度（全校児童数 320人）」の形
    it "学校名・年度・全校児童数を見出しの形でつなぐ" do
      user = build(:user, school_name: "ひまわり小学校", academic_year: "2026", current_enrollment: 320)
      expect(user.heading_label).to eq("ひまわり小学校 2026年度（全校児童数 320人）")
    end
  end
end
