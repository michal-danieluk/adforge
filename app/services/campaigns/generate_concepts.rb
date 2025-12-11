# app/services/campaigns/generate_concepts.rb
module Campaigns
  class GenerateConcepts
    def initialize(campaign)
      @campaign = campaign
      @brand = campaign.brand
    end

    def call
      # 1. Construct the prompt
      prompt_text = build_prompt

      # 2. Call the LLM
      llm = Rails.application.config.langchain_llm
      raise "LLM client not configured" unless llm

      response = llm.chat(
        messages: [{ role: "user", content: prompt_text }],
        model: "gpt-4o-mini", # As specified in MVP_BRAIN_SPEC.md
        temperature: 0.7,
        response_format: { type: "json_object" } # Request JSON output
      )

      # 3. Parse and validate JSON response
      parsed_response = JSON.parse(response.completion)
      concepts = parsed_response["concepts"] # Assuming the LLM returns a key called 'concepts'

      validate_concepts!(concepts)

      # 4. Create Creative records
      creatives = create_creatives(concepts, response)

      creatives
    rescue JSON::ParserError => e
      raise "LLM response was not valid JSON: #{e.message}"
    rescue => e
      raise "Error generating concepts: #{e.message}"
    end

    private

    def build_prompt
      <<~PROMPT
        You are an expert advertising copywriter for the brand "#{@brand.name}".
        The brand's tone of voice is "#{@brand.tone_of_voice}".

        Generate exactly 3 distinct ad concepts for a social media campaign.
        Each concept must include a "headline", "body", and "background_prompt".
        The "background_prompt" should be a concise, descriptive phrase suitable for an AI image generator (e.g., DALL-E).

        Campaign Details:
        Product: #{@campaign.product_name}
        Target Audience: #{@campaign.target_audience}
        Description: #{@campaign.description}

        Ensure the output is a JSON object with a single key "concepts", which is an array of 3 ad concepts.

        Example JSON Structure:
        {
          "concepts": [
            {
              "headline": "Catchy Headline 1",
              "body": "Compelling body text for concept 1.",
              "background_prompt": "A vibrant image of [something related to product]."
            },
            {
              "headline": "Catchy Headline 2",
              "body": "Compelling body text for concept 2.",
              "background_prompt": "An artistic representation of [another aspect]."
            },
            {
              "headline": "Catchy Headline 3",
              "body": "Compelling body text for concept 3.",
              "background_prompt": "A minimalist design featuring [key product element]."
            }
          ]
        }
      PROMPT
    end

    def validate_concepts!(concepts)
      unless concepts.is_a?(Array) && concepts.size == 3
        raise "Expected JSON to contain an array of exactly 3 concepts, but received: #{concepts.inspect}"
      end

      concepts.each do |concept|
        unless concept.is_a?(Hash) && concept["headline"].present? && concept["body"].present? && concept["background_prompt"].present?
          raise "Each concept must be a hash with 'headline', 'body', and 'background_prompt' keys: #{concept.inspect}"
        end
      end
    end

    def create_creatives(concepts, response)
      creatives = []
      token_usage = response.usage || {}
      prompt_tokens = token_usage["prompt_tokens"] || 0
      completion_tokens = token_usage["completion_tokens"] || 0
      total_tokens = token_usage["total_tokens"] || 0
      model_name = response.model || "gpt-4o-mini" # Fallback if model not in response

      # For a simple gpt-4o-mini, the pricing is usually $0.00015 / 1K tokens for input and $0.0006 / 1K tokens for output.
      # This can vary. For now, a placeholder or a very basic calculation.
      # A more robust solution would query the actual pricing or use a gem that handles this.
      # For MVP, we'll make a simplified assumption or get exact pricing if available from Langchain.
      # Let's assume a rough total cost for now, or fetch from a more accurate source if Langchain provides it.
      
      # Placeholder for cost calculation (actual values depend on OpenAI pricing and Langchain integration)
      # Assuming 15 cents per 1M prompt tokens, 60 cents per 1M completion tokens for gpt-4o-mini
      # Convert to cents for storage
      cost_cents_prompt = (prompt_tokens.to_f / 1_000_000) * 15 # in cents per million
      cost_cents_completion = (completion_tokens.to_f / 1_000_000) * 60 # in cents per million
      total_cost_cents = (cost_cents_prompt + cost_cents_completion).round # round to nearest cent

      concepts.each do |concept|
        creatives << @campaign.creatives.create!(
          headline: concept["headline"],
          body: concept["body"],
          background_prompt: concept["background_prompt"],
          ai_metadata: {
            model: model_name,
            prompt_tokens: prompt_tokens,
            completion_tokens: completion_tokens,
            total_tokens: total_tokens,
            cost_cents: total_cost_cents / concepts.size # Distribute total cost among creatives
          },
          status: :pending # Initial status for creatives
        )
      end
      creatives
    end
  end
end