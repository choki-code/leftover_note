class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date_provided, null: false
      # 実食数（出席人数）。任意。全校児童数（users.current_enrollment）とは別物
      t.integer :attendance_count
      # 3-G 集計対象外。除外した日も一覧には残す（3-H）ので、行は消さずに印を付ける
      t.boolean :excluded_from_stats, null: false, default: false
      # 除外の理由。DB は空を許し、モデル側で「除外するなら必須」にする
      t.text :exclusion_reason

      t.timestamps
    end

    # 3-B 同じ日の献立は1件だけ
    add_index :menus, [ :user_id, :date_provided ], unique: true
  end
end
