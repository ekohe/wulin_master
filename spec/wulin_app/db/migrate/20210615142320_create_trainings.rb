class CreateTrainings < ActiveRecord::Migration[5.0]
  def change
    create_table :trainings do |t|
      t.string :name
      t.integer :teacher_id
      t.integer :client_id

      t.timestamps
    end
  end
end