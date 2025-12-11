class RenderCreativeJob < ApplicationJob
  queue_as :default

  def perform(creative_id)
    creative = Creative.find(creative_id)
    Creatives::GenerateImage.new(creative).call
  rescue => e
    Rails.logger.error "RenderCreativeJob failed: #{e.message}"
    # We could update AI metadata with error if needed
  end
end