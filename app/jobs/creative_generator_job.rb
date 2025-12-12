require "open-uri"

class CreativeGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(creative_id)
    creative = Creative.find(creative_id)

    # Note: Status remains 'pending' during generation
    # Only update to 'generated' on success or 'failed' on error

    # Generate placeholder background image
    # In the future, this will call DALL-E with creative.image_prompt
    background_url = generate_placeholder_background(creative)

    # Download and attach
    creative.raw_background.attach(
      io: URI.open(background_url),
      filename: "bg_#{creative.id}.png",
      content_type: "image/png"
    )

    # Mark as generated
    creative.update!(status: "generated")

    # Trigger image composition job
    ImageComposerJob.perform_later(creative.id)
  rescue => e
    creative&.update!(status: "failed")
    Rails.logger.error("Creative generation failed for creative #{creative_id}: #{e.message}")
    raise
  end

  private

  def generate_placeholder_background(creative)
    # Use reliable placehold.co service with headline text
    # Encode headline for URL
    text = URI.encode_www_form_component(creative.headline || "Ad Creative")

    # Use neutral colors for reliability
    "https://placehold.co/1080x1080/EEEEEE/333333/png?text=#{text}"
  end
end
