class CampaignsController < ApplicationController
  before_action :require_authentication
  before_action :set_campaign, only: %i[ show edit update destroy ]

  # GET /campaigns or /campaigns.json
  def index
    @campaigns = Current.user.campaigns.includes(:brand).order(created_at: :desc)
  end

  # GET /campaigns/1 or /campaigns/1.json
  def show
    @recent_creatives = @campaign.creatives.successful.recent.limit(3)
  end

  # GET /campaigns/new
  def new
    @campaign = Campaign.new
    @campaign.brand_id = params[:brand_id] if params[:brand_id]
    @brands = Current.user.brands.order(:name)
  end

  # GET /campaigns/1/edit
  def edit
    @brands = Current.user.brands.order(:name)
  end

  # POST /campaigns or /campaigns.json
  def create
    @campaign = Campaign.new(campaign_params)
    @brands = Current.user.brands.order(:name)

    # Validate that the selected brand belongs to current user
    if @campaign.brand_id && !Current.user.brands.exists?(@campaign.brand_id)
      @campaign.errors.add(:brand, "is invalid")
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @campaign.errors, status: :unprocessable_entity }
      end
      return
    end

    respond_to do |format|
      if @campaign.save
        format.html { redirect_to @campaign, notice: "Campaign was successfully created." }
        format.json { render :show, status: :created, location: @campaign }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @campaign.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /campaigns/1 or /campaigns/1.json
  def update
    respond_to do |format|
      if @campaign.update(campaign_params)
        format.html { redirect_to @campaign, notice: "Campaign was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @campaign }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @campaign.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /campaigns/1 or /campaigns/1.json
  def destroy
    @campaign.destroy!

    respond_to do |format|
      format.html { redirect_to campaigns_path, notice: "Campaign was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_campaign
      @campaign = Current.user.campaigns.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def campaign_params
      params.expect(campaign: [ :brand_id, :product_name, :target_audience, :description ])
    end
end
