module Campaigns
  class GeneratePlan
    # Cost per 1k tokens for gpt-4o-mini (approximate)
    # Input: $0.00015/1k, Output: $0.0006/1k
    # We'll use a blended rate of $0.0006/1k for simplicity
    COST_PER_1K_TOKENS = 0.0006

    attr_reader :campaign, :llm

    def initialize(campaign)
      @campaign = campaign
      @llm = Rails.application.config.langchain_llm
    end

    def call
      response = generate_concepts
      concepts = parse_response(response)
      create_creatives(concepts, response)
    rescue => e
      Rails.logger.error("Failed to generate campaign plan: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    private

    def generate_concepts
      prompt = build_prompt

      llm.chat(
        messages: [
          { role: "system", content: system_message },
          { role: "user", content: prompt }
        ],
        temperature: 0.7,
        response_format: { type: "json_object" }
      )
    end

    def system_message
      <<~SYSTEM.strip
        You are an expert advertising copywriter. Generate social media ad concepts based on the user's requirements.

        CRITICAL: Respond ONLY with valid JSON in this exact format:
        {
          "concepts": [
            {
              "headline": "Short, punchy headline (max 8 words)",
              "body": "Compelling ad body text (2-3 sentences, max 100 words)",
              "background_prompt": "Detailed DALL-E prompt for background image (describe visual style, colors, mood, composition)"
            }
          ]
        }

        Generate exactly 3 unique concepts with different creative angles.
      SYSTEM
    end

    def build_prompt
      brand = campaign.brand
      colors = brand.brand_colors.map(&:hex_value).join(", ")

      <<~PROMPT.strip
        Create 3 social media ad concepts for:

        Brand: #{brand.name}
        Tone: #{brand.tone_of_voice}
        Brand Colors: #{colors}

        Product/Campaign: #{campaign.product_name}
        Target Audience: #{campaign.target_audience}
        #{campaign.description.present? ? "Additional Context: #{campaign.description}" : ""}

        Each concept should:
        - Have a unique creative angle
        - Match the #{brand.tone_of_voice} tone
        - Appeal to #{campaign.target_audience}
        - Include a clear call-to-action in the body text

        Background prompts should suggest visuals that complement the brand colors (#{colors}) and create visual interest.
      PROMPT
    end

    def parse_response(response)
      # Extract the content from the response
      content = response.chat_completion.dig("choices", 0, "message", "content")

      unless content
        raise "No content in API response"
      end

      parsed = JSON.parse(content)
      concepts = parsed["concepts"]

      unless concepts.is_a?(Array) && concepts.length == 3
        raise "Expected 3 concepts, got #{concepts&.length || 0}"
      end

      # Validate each concept has required fields
      concepts.each_with_index do |concept, i|
        %w[headline body background_prompt].each do |field|
          unless concept[field].present?
            raise "Concept #{i + 1} missing #{field}"
          end
        end
      end

      concepts
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response: #{content}")
      raise "Invalid JSON from AI: #{e.message}"
    end

    def create_creatives(concepts, response)
      # Calculate cost from token usage
      usage = response.chat_completion.dig("usage")
      total_tokens = usage&.dig("total_tokens") || 0
      cost_cents = calculate_cost_cents(total_tokens)

      ActiveRecord::Base.transaction do
        concepts.map do |concept|
          campaign.creatives.create!(
            headline: concept["headline"],
            ad_copy: concept["body"],
            image_prompt: concept["background_prompt"],
            ai_model: "gpt-4o-mini",
            ai_tokens: total_tokens / 3, # Divide tokens across 3 creatives
            ai_cost_cents: cost_cents / 3, # Divide cost across 3 creatives
            status: "pending"
          )
        end
      end
    end

    def calculate_cost_cents(tokens)
      # Convert tokens to cost in cents
      # (tokens / 1000) * cost_per_1k * 100 (to convert to cents)
      ((tokens / 1000.0) * COST_PER_1K_TOKENS * 100).round
    end
  end
end
