require "open-uri"

class CreativeGeneratorJob < ApplicationJob
  queue_as :default

  def perform(creative_id)
    creative = Creative.find(creative_id)
    creative.update!(status: "generating")

    # PLACEHOLDER: Generate fake background
    background_url = generate_placeholder_background(creative)

    # Download and attach
    creative.raw_background.attach(
      io: URI.open(background_url),
      filename: "bg_#{creative.id}.png"
    )

    # PLACEHOLDER: Generate fake ad copy
    ad_copy = generate_placeholder_copy(creative)

    # Update creative
    creative.update!(
      ad_copy: ad_copy,
      status: "generated"
    )

    # Trigger image composition job
    ImageComposerJob.perform_later(creative.id)
  rescue => e
    creative&.update!(status: "failed")
    Rails.logger.error("Creative generation failed: #{e.message}")
    raise
  end

  private

  def generate_placeholder_background(creative)
    brand = creative.campaign.brand
    color = brand.primary_color.delete("#")

    # Use placehold.co with brand color
    "https://placehold.co/1080x1080/#{color}/white/png?text=AI+Background"
  end

  def generate_placeholder_copy(creative)
    campaign = creative.campaign
    brand = campaign.brand

    # Fake copy based on campaign data
    <<~COPY.strip
      Discover #{campaign.product_name}

      Perfect for #{campaign.target_audience}.
      #{brand.tone_of_voice&.capitalize || 'Premium'} quality you can trust.

      Learn more today!
    COPY
  end
end
