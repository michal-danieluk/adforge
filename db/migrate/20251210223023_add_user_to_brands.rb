class AddUserToBrands < ActiveRecord::Migration[8.0]
  def change
    # Add column as nullable first
    add_reference :brands, :user, null: true, foreign_key: true

    # Create default user and assign existing brands
    reversible do |dir|
      dir.up do
        # Create a default user for existing brands
        default_user = User.create!(
          email_address: "admin@adforge.local",
          password: "password",
          password_confirmation: "password"
        )

        # Assign all existing brands to this user
        Brand.update_all(user_id: default_user.id)
      end
    end

    # Now make it not null
    change_column_null :brands, :user_id, false
  end
end
