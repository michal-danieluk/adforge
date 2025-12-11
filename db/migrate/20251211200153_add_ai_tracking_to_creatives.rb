class AddAiTrackingToCreatives < ActiveRecord::Migration[8.1]
  def change
    add_column :creatives, :ai_model, :string
    add_column :creatives, :ai_tokens, :integer
    add_column :creatives, :ai_cost_cents, :integer
    add_column :creatives, :headline, :string
    add_column :creatives, :image_prompt, :text
  end
end
