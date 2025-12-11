class CreateAppConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :app_configs do |t|
      t.string :gemini_api_key

      t.timestamps
    end
  end
end
