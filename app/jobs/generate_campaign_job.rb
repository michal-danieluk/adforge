class GenerateCampaignJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 2
  discard_on ActiveRecord::RecordNotFound

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)

    # Step 1: Set status to processing
    campaign.update!(status: :processing)

    # Step 2: Generate concepts using AI
    creatives = Campaigns::GenerateConcepts.new(campaign).call

    # Step 3: On success - set status to completed
    campaign.update!(status: :completed)

    # Note: Phase B (image generation) will be implemented later
    # For now, creatives have text only (headline, body, background_prompt)

  rescue => e
    # Step 4: On failure - set status to failed and log error
    campaign.update!(status: :failed) if campaign

    Rails.logger.error("Campaign generation failed for campaign #{campaign_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    raise # Re-raise to trigger retry logic
  end
end
