class CreateCourses < ActiveRecord::Migration[5.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :title
      t.string :desc
      t.integer :training_id

      t.timestamps
    end

    add_index(:courses, [:name, :title], unique: true)
  end
end
