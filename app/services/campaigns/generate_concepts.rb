module Campaigns
  class GenerateConcepts
    # Cost per 1k tokens for gpt-4o-mini (approximate)
    # Input: $0.00015/1k, Output: $0.0006/1k tokens
    # Using blended rate for simplicity
    COST_PER_1K_TOKENS = 0.0006

    attr_reader :campaign, :llm

    def initialize(campaign)
      @campaign = campaign
      @llm = Rails.application.config.langchain_llm
    end

    # Main entry point - returns array of created Creatives
    def call
      response = generate_from_llm
      concepts = parse_and_validate_json(response)
      create_creatives(concepts, response)
    rescue => e
      Rails.logger.error("Failed to generate concepts for campaign #{campaign.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    private

    def generate_from_llm
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
        Jesteś ekspertem w tworzeniu tekstów reklamowych, specjalizującym się w reklamach w mediach społecznościowych.
        Twórz kreatywne koncepcje reklam na podstawie tożsamości marki i wymagań kampanii.

        KRYTYCZNE: Musisz odpowiedzieć WYŁĄCZNIE poprawnym JSON-em w tym DOKŁADNYM formacie:
        {
          "concepts": [
            {
              "headline": "Krótki, chwytliwy nagłówek (maks. 8 słów)",
              "body": "Przekonujący tekst główny reklamy (2-3 zdania, maks. 100 słów)",
              "background_prompt": "Szczegółowy prompt dla DALL-E 3 do wygenerowania tła (opisz styl wizualny, kolory, nastrój, kompozycję, oświetlenie) - PROMPT W JĘZYKU ANGIELSKIM"
            }
          ]
        }

        Wymagania:
        - Wygeneruj dokładnie 3 unikalne koncepcje
        - Każda koncepcja musi mieć inny kreatywny kierunek
        - Nagłówki powinny przyciągać uwagę i być zwięzłe
        - Tekst główny powinien zawierać wyraźne wezwanie do działania
        - Prompty do obrazów powinny być szczegółowe i konkretne (w języku angielskim dla DALL-E)

        JĘZYK:
        - headline i body: PO POLSKU
        - background_prompt: PO ANGIELSKU (dla DALL-E 3)
      SYSTEM
    end

    def build_prompt
      brand = campaign.brand
      colors = brand.brand_colors.map(&:hex_value).join(", ")

      # Map Polish tone names to Polish descriptions
      tone_map = {
        "professional" => "profesjonalny",
        "casual" => "swobodny",
        "friendly" => "przyjazny",
        "authoritative" => "autorytatywny"
      }
      tone_pl = tone_map[brand.tone_of_voice] || brand.tone_of_voice

      <<~PROMPT.strip
        Stwórz 3 różne koncepcje reklam dla mediów społecznościowych:

        TOŻSAMOŚĆ MARKI:
        - Nazwa: #{brand.name}
        - Ton komunikacji: #{tone_pl}
        - Kolory marki: #{colors}

        KAMPANIA:
        - Produkt/Temat: #{campaign.product_name}
        - Grupa docelowa: #{campaign.target_audience}
        #{campaign.description.present? ? "- Dodatkowy kontekst: #{campaign.description}" : ""}

        WYMAGANIA DLA KAŻDEJ KONCEPCJI:
        1. Nagłówek (headline): Stwórz unikalny przekaz skierowany bezpośrednio do grupy: #{campaign.target_audience}
        2. Tekst główny (body): Dopasuj ton #{tone_pl} i dodaj wyraźne wezwanie do działania (CTA)
        3. Prompt do obrazu (background_prompt): Zaproponuj wizualizację, która:
           - Uzupełnia kolory marki (#{colors})
           - Tworzy zainteresowanie wizualne i emocjonalny wpływ
           - Jest odpowiednia dla profesjonalnej reklamy w social media
           - Może być wygenerowana przez DALL-E 3
           - NAPISZ PROMPT PO ANGIELSKU (dla DALL-E API)

        Każda z 3 koncepcji powinna być wyraźnie różna w podejściu i komunikacie.

        PAMIĘTAJ: headline i body po polsku, background_prompt po angielsku!
      PROMPT
    end

    def parse_and_validate_json(response)
      # Extract content from OpenAI response via langchainrb
      # Try different ways to get the content depending on langchainrb version
      content = nil

      # Method 1: Try response.completion (simple text)
      if response.respond_to?(:completion)
        content = response.completion
      end

      # Method 2: Try response.chat_completion (full API response)
      if content.nil? && response.respond_to?(:chat_completion)
        completion = response.chat_completion

        # If it's a string, parse it first
        completion = JSON.parse(completion) if completion.is_a?(String)

        # Extract content from the nested structure
        content = completion.dig("choices", 0, "message", "content") if completion.is_a?(Hash)
      end

      unless content.present?
        raise "No content in API response. Response methods: #{response.methods.grep(/complet/)}"
      end

      # Parse the JSON content (the actual concepts)
      parsed = JSON.parse(content)
      concepts = parsed["concepts"]

      # Validate structure
      unless concepts.is_a?(Array) && concepts.length == 3
        raise "Expected 3 concepts, got #{concepts&.length || 0}"
      end

      # Validate each concept has required fields
      concepts.each_with_index do |concept, i|
        %w[headline body background_prompt].each do |field|
          unless concept[field].present?
            raise "Concept #{i + 1} missing required field: #{field}"
          end
        end
      end

      concepts
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response: #{content}")
      raise "Invalid JSON from AI: #{e.message}"
    end

    def create_creatives(concepts, response)
      # Extract token usage and calculate cost
      # Parse chat_completion the same way as in parse_and_validate_json
      completion = response.chat_completion
      completion = JSON.parse(completion) if completion.is_a?(String)

      usage = completion.dig("usage") if completion.is_a?(Hash)
      total_tokens = usage&.dig("total_tokens") || 0
      model = completion.dig("model") || "gpt-4o-mini" if completion.is_a?(Hash)
      model ||= "gpt-4o-mini"
      cost_cents = calculate_cost_cents(total_tokens)

      # Build metadata
      metadata = {
        model: model,
        total_tokens: total_tokens,
        cost_cents: cost_cents,
        prompt_tokens: usage&.dig("prompt_tokens"),
        completion_tokens: usage&.dig("completion_tokens"),
        generated_at: Time.current.iso8601
      }

      # Create all 3 creatives in a transaction
      ActiveRecord::Base.transaction do
        concepts.map do |concept|
          campaign.creatives.create!(
            headline: concept["headline"],
            body: concept["body"],
            background_prompt: concept["background_prompt"],
            status: :generated,  # Phase A: text is ready, no image generation yet
            ai_metadata: metadata.merge(
              tokens_share: total_tokens / 3 # Divide evenly across concepts
            ),
            # Also populate legacy columns for backward compatibility
            ai_model: model,
            ai_tokens: total_tokens / 3,
            ai_cost_cents: cost_cents / 3
          )
        end
      end
    end

    def calculate_cost_cents(tokens)
      # (tokens / 1000) * cost_per_1k * 100 (to convert to cents)
      ((tokens / 1000.0) * COST_PER_1K_TOKENS * 100).round
    end
  end
end
