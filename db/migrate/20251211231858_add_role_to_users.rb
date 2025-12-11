class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :integer, default: 0
    # Set user ID 1 to admin (1) if exists
    execute "UPDATE users SET role = 1 WHERE id = 1"
  end

  def down
    remove_column :users, :role
  end
end