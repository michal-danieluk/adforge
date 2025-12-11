# Langchain configuration for AI integration
require "langchain"

# Initialize the OpenAI client
# Access via: Rails.application.config.langchain_llm
# API key should be stored in rails credentials under openai:api_key
Rails.application.config.to_prepare do
  api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]

  Rails.application.config.langchain_llm = Langchain::LLM::OpenAI.new(
    api_key: api_key,
    default_options: {
      model: "gpt-4o-mini",
      temperature: 0.7
    }
  )
end
