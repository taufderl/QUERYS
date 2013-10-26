class AddCountryAndRelationToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :country, :string
    add_column :questions, :relation, :string
  end
end
