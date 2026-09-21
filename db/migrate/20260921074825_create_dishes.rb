class CreateDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :dishes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false
      # 論理削除（2-D）。NULL なら生きている。日時を入れることで「いつ消したか」も残る
      t.datetime :deleted_at

      t.timestamps
    end

    # 2-C 同じ名前を登録できない。ただし 2-E のため「生きている行だけ」を見る。
    # 条件なしの unique にすると、論理削除した名前を二度と使えなくなる
    add_index :dishes, [ :user_id, :name ],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_dishes_on_user_id_and_name_alive"
  end
end
