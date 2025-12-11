class UpdateCreativesForPhaseA < ActiveRecord::Migration[8.1]
  def change
    # Rename columns to match spec
    rename_column :creatives, :image_prompt, :background_prompt
    rename_column :creatives, :ad_copy, :body

    # Add ai_metadata JSON column
    add_column :creatives, :ai_metadata, :json, default: {}

    # Convert status from string to integer enum
    # First, remove the old string status column
    remove_column :creatives, :status, :string

    # Add new integer status column
    add_column :creatives, :status, :integer, default: 0, null: false
    add_index :creatives, :status
  end
end
