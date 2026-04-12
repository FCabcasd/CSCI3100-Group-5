class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false
      t.string :full_name
      t.string :hashed_password, null: false
      t.integer :role, default: 0
      t.references :tenant, null: true, foreign_key: true
      t.boolean :is_active, default: true
      t.integer :points, default: 100
      t.datetime :suspension_until

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
