class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands do |t|
      t.string :name
      t.string :tone_of_voice

      t.timestamps
    end
  end
end
