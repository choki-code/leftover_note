class AddSchoolProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :school_name, :string
    add_column :users, :academic_year, :string
    add_column :users, :current_enrollment, :integer
  end
end
