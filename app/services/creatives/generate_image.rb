require 'faraday'
require 'json'
require 'base64'
require 'tempfile'
require "image_processing/vips"

module Creatives
  class GenerateImage
    def initialize(creative)
      @creative = creative
    end

    def call
      api_key = fetch_api_key
      
      # 2. API Request
      conn = Faraday.new(url: "https://generativelanguage.googleapis.com") do |f|
        f.headers["x-goog-api-key"] = api_key
        f.headers["Content-Type"] = "application/json"
        f.adapter Faraday.default_adapter
      end

      response = conn.post("/v1beta/models/imagen-3.0-generate-001:predict") do |req|
        req.body = {
          instances: [
            { prompt: @creative.background_prompt }
          ],
          parameters: {
            sampleCount: 1,
            aspectRatio: "1:1"
          }
        }.to_json
      end

      unless response.success?
        error_msg = "Imagen 3 API Error: #{response.status} - #{response.body}"
        raise error_msg
      end

      response_body = JSON.parse(response.body)
      
      if response_body['predictions'].blank? || response_body['predictions'][0]['bytesBase64Encoded'].blank?
         raise "Imagen 3 API returned no image data: #{response_body}"
      end
      
      base64_image = response_body['predictions'][0]['bytesBase64Encoded']
      image_data = Base64.decode64(base64_image)

      # 4. Composition (Libvips)
      process_and_attach(image_data)
      
      @creative
    end

    private

    def fetch_api_key
      # AppConfig.load returns a new instance if empty, so we check existence or create logic
      # Actually we used AppConfig.current in controller which does first || new
      # Here we want to read it.
      key = AppConfig.first&.gemini_api_key.presence || ENV["GEMINI_API_KEY"]
      raise StandardError.new("Missing Google API Key. Go to Settings.") unless key.present?
      key
    end

    def process_and_attach(raw_image_data)
      Tempfile.open(["raw_imagen", ".png"], binmode: true) do |raw_file|
        raw_file.write(raw_image_data)
        raw_file.rewind

        # Basic processing: Resize to 1080x1080
        # In a real implementation, we would construct a Vips overlay here.
        # For MVP stability, we resize to ensure the image is standard.
        processed = ImageProcessing::Vips
                      .source(raw_file.path)
                      .resize_to_fill(1080, 1080)
                      .call

        @creative.final_image.attach(
          io: File.open(processed.path),
          filename: "creative_#{@creative.id}.png",
          content_type: "image/png"
        )
      end
    end
  end
end
