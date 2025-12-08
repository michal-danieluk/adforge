class CreateBrandColors < ActiveRecord::Migration[8.0]
  def change
    create_table :brand_colors do |t|
      t.references :brand, null: false, foreign_key: true
      t.string :hex_value
      t.boolean :primary

      t.timestamps
    end
  end
end
