class CreateRelations < ActiveRecord::Migration
  def change
    create_table :relations do |t|
      t.string :key
      t.string :relation

      t.timestamps
    end
  end
end
