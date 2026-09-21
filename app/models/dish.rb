class Dish < ApplicationRecord
  belongs_to :user

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
end
