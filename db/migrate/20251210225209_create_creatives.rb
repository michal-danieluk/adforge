class CreateCreatives < ActiveRecord::Migration[8.0]
  def change
    create_table :creatives do |t|
      t.references :campaign, null: false, foreign_key: true
      t.text :ad_copy
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_index :creatives, :status
  end
end
