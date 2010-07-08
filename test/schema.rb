ActiveRecord::Schema.define(:version => 0) do
  create_table :items, :force => true do |t|
    t.string :name
    t.string :description
    t.integer :person_id
    t.integer :category_id
    t.date :due_on
    t.timestamps
  end
  create_table :people, :force => true do |t|
    t.string :username
    t.string :role
    t.string :internal_calculation
    t.timestamps
  end
  create_table :categories, :force => true do |t|
    t.string :name
    t.timestamps
  end
end