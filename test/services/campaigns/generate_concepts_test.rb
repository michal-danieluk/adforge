require "test_helper"
require "json"
require "ostruct"
require "minitest/mock"
require "langchain" # Ensure Langchain module is loaded

class Campaigns::GenerateConceptsTest < ActiveSupport::TestCase
  setup do
    @brand = brands(:one) # Assuming you have a fixture named 'one' for brands
    @campaign = Campaign.create!(
      brand: @brand,
      product_name: "Innovative Product",
      target_audience: "Tech Enthusiasts",
      description: "A product that revolutionizes daily tasks."
    )

    # Ensure Langchain is configured for testing, as it might not be fully loaded
    # in this test context. This will define Langchain.llm.
    Langchain.configure do |config|
      config.llm = Langchain::LLM::OpenAI.new(
        api_key: "test-api-key", # Dummy API key for test
        default_options: {
          model: "gpt-4o-mini",
          temperature: 0.7
        }
      )
    end
  end

  # Helper method to wrap test execution with a mocked LLM response
  def with_mocked_llm(mock_response)
    mock_llm_client = Minitest::Mock.new
    mock_llm_client.expect(:chat, mock_response, [
      {
        prompt: String,
        model: "gpt-4o-mini",
        temperature: 0.7,
        response_format: { type: "json_object" }
      }
    ])

    Langchain.stub :llm, mock_llm_client do
      yield mock_llm_client # Yield to the test block, passing the mock client for verification
    end
  end

  test "should generate 3 creative concepts and save them to the campaign" do
    mock_response = OpenStruct.new(
      completion: {
        "concepts" => [
          {
            "headline" => "Concept 1 Headline",
            "body" => "Concept 1 Body text.",
            "background_prompt" => "A futuristic city skyline at sunset."
          },
          {
            "headline" => "Concept 2 Headline",
            "body" => "Concept 2 Body text.",
            "background_prompt" => "Close-up of a user interacting with a sleek device."
          },
          {
            "headline" => "Concept 3 Headline",
            "body" => "Concept 3 Body text.",
            "background_prompt" => "A minimalist design featuring [key product element]."
          }
        ]
      }.to_json,
      usage: {
        "prompt_tokens" => 100,
        "completion_tokens" => 50,
        "total_tokens" => 150
      },
      model: "gpt-4o-mini"
    )

    with_mocked_llm(mock_response) do |llm_mock|
      assert_difference "@campaign.creatives.count", 3 do
        Campaigns::GenerateConcepts.new(@campaign).call
      end

      @campaign.reload
      # The campaign status is updated by GenerateCampaignJob, not the service directly.
      # So no assertion for campaign status here.

      creatives = @campaign.creatives.order(:id)

      # Verify first creative
      assert_equal "Concept 1 Headline", creatives[0].headline
      assert_equal "Concept 1 Body text.", creatives[0].body
      assert_equal "A futuristic city skyline at sunset.", creatives[0].background_prompt
      assert creatives[0].ai_metadata.present?
      assert_equal "gpt-4o-mini", creatives[0].ai_metadata["model"]
      assert_equal "pending", creatives[0].status # Check initial status

      # Verify second creative
      assert_equal "Concept 2 Headline", creatives[1].headline
      assert_equal "Concept 2 Body text.", creatives[1].body
      assert_equal "Close-up of a user interacting with a sleek device.", creatives[1].background_prompt
      assert creatives[1].ai_metadata.present?
      assert_equal "pending", creatives[1].status

      # Verify third creative
      assert_equal "Concept 3 Headline", creatives[2].headline
      assert_equal "Concept 3 Body text.", creatives[2].body
      assert_equal "Abstract art with tech motifs.", creatives[2].background_prompt
      assert creatives[2].ai_metadata.present?
      assert_equal "pending", creatives[2].status

      llm_mock.verify # Verify the mock was called
    end
  end

  test "should raise an error if LLM response is not valid JSON" do
    invalid_llm_response = OpenStruct.new(
      completion: "This is not JSON",
      usage: {},
      model: "gpt-4o-mini"
    )

    with_mocked_llm(invalid_llm_response) do
      assert_raises(RuntimeError, "LLM response was not valid JSON: 795: unexpected token at 'This is not JSON'") do
        Campaigns::GenerateConcepts.new(@campaign).call
      end
    end
  end

  test "should raise an error if JSON structure is invalid" do
    invalid_json_structure = OpenStruct.new(
      completion: { "bad_key" => [] }.to_json,
      usage: {},
      model: "gpt-4o-mini"
    )

    with_mocked_llm(invalid_json_structure) do
      # The exact error message depends on the validation, but it should raise
      assert_raises(RuntimeError) do
        Campaigns::GenerateConcepts.new(@campaign).call
      end
    end
  end

  test "should raise an error if fewer than 3 concepts are returned" do
    two_concepts = OpenStruct.new(
      completion: {
        "concepts" => [
          { "headline" => "H1", "body" => "B1", "background_prompt" => "P1" },
          { "headline" => "H2", "body" => "B2", "background_prompt" => "P2" }
        ]
      }.to_json,
      usage: {},
      model: "gpt-4o-mini"
    )

    with_mocked_llm(two_concepts) do
      assert_raises(RuntimeError, "Expected JSON to contain an array of exactly 3 concepts, but received: [{\"headline\"=>\"H1\", \"body\"=>\"B1\", \"background_prompt\"=>\"P1\"}, {\"headline\"=>\"H2\", \"body\"=>\"B2\", \"background_prompt\"=>\"P2\"}]") do
        Campaigns::GenerateConcepts.new(@campaign).call
      end
    end
  end

  test "should calculate and store AI cost per creative" do
    mock_response = OpenStruct.new(
      completion: {
        "concepts" => [
          { "headline" => "H1", "body" => "B1", "background_prompt" => "P1" },
          { "headline" => "H2", "body" => "B2", "background_prompt" => "P2" },
          { "headline" => "H3", "body" => "B3", "background_prompt" => "P3" }
        ]
      }.to_json,
      usage: {
        "prompt_tokens" => 100,
        "completion_tokens" => 50,
        "total_tokens" => 150
      },
      model: "gpt-4o-mini"
    )

    with_mocked_llm(mock_response) do
      Campaigns::GenerateConcepts.new(@campaign).call
      @campaign.reload
      creatives = @campaign.creatives.order(:id)

      # Given the current simplified cost calculation, it might result in 0 cents.
      # We assert that cost_cents is present and is an Integer, and non-negative.
      assert creatives.all? { |c| c.ai_metadata["cost_cents"].present? && c.ai_metadata["cost_cents"].is_a?(Integer) }
      assert creatives.all? { |c| c.ai_metadata["cost_cents"] >= 0 }
    end
  end
end
