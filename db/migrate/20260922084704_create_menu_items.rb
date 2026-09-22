class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :dish, null: false, foreign_key: true
      # 提供量（kg）。float だと合計してから割る計算で誤差が乗るので decimal
      t.decimal :portion_size, precision: 6, scale: 2, null: false
      # 残食量（kg）。4-C 献立登録時は空でよい（給食後に入力する運用）
      t.decimal :weight_of_leftovers, precision: 6, scale: 2
      # 4-A 改善事項。学級閉鎖などの事情もここに書く（備考欄は作らない・4-F）
      t.text :items_for_improvement

      t.timestamps
    end

    # 1つの献立の中で同じ料理を2行書けない。画面にエラーを出すのはモデルの仕事で、
    # ここは同時に2回押されたときの最後の砦
    add_index :menu_items, [ :menu_id, :dish_id ], unique: true
  end
end
