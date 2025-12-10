class ImageComposerJob < ApplicationJob
  queue_as :default

  def perform(creative_id)
    creative = Creative.find(creative_id)

    # PLACEHOLDER: For now, final_image = raw_background
    # Later (Iteration 5): This will overlay logo, text, brand colors using image_processing

    if creative.raw_background.attached?
      creative.final_image.attach(
        io: StringIO.new(creative.raw_background.download),
        filename: "final_#{creative.id}.png",
        content_type: "image/png"
      )
    end
  rescue => e
    Rails.logger.error("Image composition failed: #{e.message}")
    raise
  end
end
