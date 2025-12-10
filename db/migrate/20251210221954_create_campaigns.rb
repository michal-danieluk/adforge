class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.references :brand, null: false, foreign_key: true
      t.string :product_name
      t.string :target_audience
      t.text :description

      t.timestamps
    end
  end
end
