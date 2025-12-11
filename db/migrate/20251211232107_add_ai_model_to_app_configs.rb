class AddAiModelToAppConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :app_configs, :ai_model, :string, default: "gemini-2.0-flash-exp"
  end
end