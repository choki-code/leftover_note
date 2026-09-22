class Dish < ApplicationRecord
  belongs_to :user
  has_many :menu_items, dependent: :restrict_with_error
  has_many :menus, through: :menu_items

  enum :category, {
    staple_food: "staple_food",   # 主食
    main_dish:   "main_dish",     # 主菜
    side_dish:   "side_dish",     # 副菜
    soup:        "soup",          # 汁物
    dessert:     "dessert"
  }, validate: true

  scope :alive, -> { where(deleted_at: nil) }

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
