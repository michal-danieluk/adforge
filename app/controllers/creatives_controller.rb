class CreativesController < ApplicationController
  before_action :require_authentication
  before_action :set_campaign, only: [:index, :create]
  before_action :set_creative, only: [:show, :destroy, :download, :render_image, :rewrite]

  def index
    @creatives = @campaign.creatives.recent
  end

  def show
    @campaign = @creative.campaign
    # View displays single creative with image and ad copy
  end

  def render_image
    RenderCreativeJob.perform_later(@creative.id)
    redirect_to campaign_path(@creative.campaign), notice: "Generating image in background..."
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

  def rewrite
    # Call Gemini Flash API to rewrite headline
    config = AppConfig.first

    unless config&.gemini_api_key.present?
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("creative_#{@creative.id}_headline", partial: "creatives/headline_error") }
        format.html { redirect_to campaign_path(@creative.campaign), alert: "Gemini API key not configured" }
      end
    end

    # Build prompt for headline rewrite
    prompt = "Rewrite this ad headline to be more punchy and viral: '#{@creative.headline}'. Max 6 words. Return ONLY the new headline, nothing else."

    begin
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=#{config.gemini_api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path + "?" + uri.query)
      request["Content-Type"] = "application/json"
      request.body = {
        contents: [{
          parts: [{ text: prompt }]
        }]
      }.to_json

      response = http.request(request)
      json = JSON.parse(response.body)

      if json["candidates"] && json["candidates"][0]
        new_headline = json["candidates"][0]["content"]["parts"][0]["text"].strip.gsub(/["']/, '')
        @creative.update!(headline: new_headline)

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to campaign_path(@creative.campaign), notice: "Headline rewritten!" }
        end
      else
        raise "Invalid API response"
      end
    rescue => e
      Rails.logger.error "Headline rewrite failed: #{e.message}"
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("creative_#{@creative.id}_headline", partial: "creatives/headline_error") }
        format.html { redirect_to campaign_path(@creative.campaign), alert: "Failed to rewrite headline" }
      end
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
