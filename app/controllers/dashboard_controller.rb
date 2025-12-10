class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    @brands_count = Current.user.brands.count
    @campaigns_count = Current.user.campaigns.count
    @recent_brands = Current.user.brands.includes(:brand_colors).order(created_at: :desc).limit(3)
    @recent_campaigns = Current.user.campaigns.includes(:brand).order(created_at: :desc).limit(5)
  end
end
