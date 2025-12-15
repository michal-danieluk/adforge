class CreativeGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(creative_id)
    creative = Creative.find(creative_id)
    campaign = creative.campaign
    brand = campaign.brand

    # Step 1: Generate ad copy using LLM
    generate_ad_copy(creative, campaign, brand)

    # Step 2: Generate image
    RenderCreativeJob.perform_later(creative.id)
  rescue => e
    creative&.update!(status: "failed")
    Rails.logger.error("Creative generation failed for creative #{creative_id}: #{e.message}")
    raise
  end

  private

  def generate_ad_copy(creative, campaign, brand)
    llm = Rails.application.config.langchain_llm
    raise "LLM client not configured" unless llm

    prompt = build_prompt(campaign, brand)

    response = llm.chat(
      messages: [{ role: "user", content: prompt }],
      model: "gpt-4o-mini",
      temperature: 0.8,
      response_format: { type: "json_object" }
    )

    parsed = JSON.parse(response.completion)

    creative.update!(
      headline: parsed["headline"],
      body: parsed["body"],
      background_prompt: parsed["background_prompt"],
      ai_metadata: {
        model: "gpt-4o-mini",
        prompt_tokens: response.prompt_tokens || 0,
        completion_tokens: response.completion_tokens || 0,
        total_tokens: response.total_tokens || 0
      }
    )
  end

  def build_prompt(campaign, brand)
    <<~PROMPT
      Jesteś ekspertem copywritingu reklamowego dla marki "#{brand.name}".
      Ton komunikacji marki: "#{brand.tone_of_voice}".

      Wygeneruj JEDNĄ koncepcję reklamową dla kampanii w mediach społecznościowych.

      Szczegóły kampanii:
      Produkt: #{campaign.product_name}
      Grupa docelowa: #{campaign.target_audience}
      Opis: #{campaign.description}

      WAŻNE:
      - headline i body muszą być w języku POLSKIM
      - background_prompt musi być w języku ANGIELSKIM (dla generatora obrazów)
      - headline: max 8 słów, chwytliwy
      - body: 1-2 zdania, przekonujące
      - background_prompt: szczegółowy opis wizualny dla AI generatora obrazów

      Zwróć JSON:
      {
        "headline": "Nagłówek po polsku",
        "body": "Treść reklamy po polsku",
        "background_prompt": "Detailed image description in English for AI image generator"
      }
    PROMPT
  end
end
