class CreativesController < ApplicationController
  before_action :require_authentication
  before_action :set_campaign, only: [:index, :create]
  before_action :set_creative, only: [:show, :destroy, :download]

  def index
    @creatives = @campaign.creatives.recent
  end

  def show
    @campaign = @creative.campaign
    # View displays single creative with image and ad copy
  end

  def create
    @creative = @campaign.creatives.create!(status: "pending")

    # Trigger async job
    CreativeGeneratorJob.perform_later(@creative.id)

    redirect_to campaign_creative_path(@campaign, @creative),
                notice: "Generating your ad... This may take 30 seconds."
  end

  def destroy
    campaign = @creative.campaign
    @creative.destroy
    redirect_to campaign_creatives_path(campaign),
                notice: "Creative deleted"
  end

  def download
    if @creative.final_image.attached?
      redirect_to rails_blob_path(@creative.final_image, disposition: "attachment"), allow_other_host: true
    else
      redirect_to campaign_creative_path(@creative.campaign, @creative),
                  alert: "Image not ready yet"
    end
  end

  private

  def set_campaign
    @campaign = Current.user.campaigns.find(params[:campaign_id])
  end

  def set_creative
    @creative = Current.user.creatives.find(params[:id])
  end
end
