class AddStatusToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :status, :integer, default: 0, null: false
    add_index :campaigns, :status
  end
end
