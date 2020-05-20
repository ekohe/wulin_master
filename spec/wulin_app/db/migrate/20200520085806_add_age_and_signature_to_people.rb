class AddAgeAndSignatureToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :age, :integer, default: 18
    add_column :people, :signature, :text
  end
end
