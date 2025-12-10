json.extract! campaign, :id, :brand_id, :product_name, :target_audience, :description, :created_at, :updated_at
json.url campaign_url(campaign, format: :json)
