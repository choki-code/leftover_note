# 料理マスタ　論理削除で消し、記録が紐づいているものは消せない
class Dish < ApplicationRecord
  belongs_to :user
  has_many :menu_items, dependent: :restrict_with_error
  has_many :menus, through: :menu_items

  # 2-B 区分。DB は string、表示名は config/locales/ja.yml の enums で持つ
  enum :category, {
    staple_food: "staple_food",   # 主食
    main_dish:   "main_dish",     # 主菜
    side_dish:   "side_dish",     # 副菜
    soup:        "soup",          # 汁物
    dessert:     "dessert"
  }, validate: true

  scope :alive, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def deleted?
    deleted_at.present?
  end

  def deletable?
    menu_items.empty?
  end

  def soft_delete
    unless deletable?
      errors.add(:base, "この料理は献立の記録に使われているため削除できません（#{menu_items.count}件の記録）")
      return false
    end
    update(deleted_at: Time.current)
  end

  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :user_id, conditions: -> { where(deleted_at: nil) } },
          if: -> { deleted_at.nil? }
  # 区分の表示名。DB には英語の文字列が入っているので ja.yml を引く
  def category_label
    I18n.t("enums.dish.category.#{category}")
  end

  # フォームの選択肢。[表示名, 値] の配列にする
  def self.category_options
    categories.keys.map { |key| [ I18n.t("enums.dish.category.#{key}"), key ] }
  end
end
