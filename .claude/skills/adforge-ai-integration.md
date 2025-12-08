# Skill: AI Integration with LangChain (AdForge)

## When to Use
When integrating AI generation:
- **Text:** Ad copy, headlines, CTAs (use LLM).
- **Images:** Backgrounds, product shots (use image generation model – TBD).

## Why LangChain?
We DON'T KNOW yet which AI providers we'll use long-term. LangChain abstracts this:
- **Text:** OpenAI GPT-4, Claude, Gemini, Llama (swappable).
- **Images:** DALL-E, Midjourney, Stable Diffusion, Flux (TBD).

**Golden Rule:** NEVER hardcode API calls directly. Always use `langchainrb`.

---

## Setup

### 1. Install Gem
Already in `Gemfile`:
```ruby
gem "langchainrb"
gem "ruby-openai"  # Or "anthropic-rb", "google-generative-ai", etc.
```

### 2. Configure Initializer
Create `config/initializers/langchain.rb`:
```ruby
require "langchain"

# For text generation (LLM)
Langchain.configure do |config|
  config.llm = Langchain::LLM::OpenAI.new(
    api_key: Rails.application.credentials.dig(:openai, :api_key),
    default_options: {
      model: "gpt-4",
      temperature: 0.7
    }
  )
end

# For image generation (when we decide on provider)
# ImageGenerator.configure do |config|
#   config.provider = :dalle  # Or :flux, :midjourney, etc.
#   config.api_key = Rails.application.credentials.dig(:dalle, :api_key)
# end
```

### 3. Store API Keys Securely
```bash
rails credentials:edit
```

Add:
```yaml
openai:
  api_key: sk-...your-key...
```

**NEVER commit API keys to Git.**

---

## Usage Pattern: Text Generation (Ad Copy)

### Step 1: Create a Job
```bash
rails g job AdCopyGenerator
```

### Step 2: Implement Job Logic
```ruby
# app/jobs/ad_copy_generator_job.rb
class AdCopyGeneratorJob < ApplicationJob
  queue_as :default

  def perform(creative_id)
    creative = Creative.find(creative_id)
    campaign = creative.campaign
    brand = campaign.brand

    prompt = build_prompt(brand, campaign)
    
    response = Langchain.llm.complete(prompt: prompt)
    
    creative.update!(
      ad_copy: response.completion,
      status: "generated"
    )
  rescue => e
    creative.update!(status: "failed", error_message: e.message)
    raise  # Re-raise to trigger retry (Solid Queue handles this)
  end

  private

  def build_prompt(brand, campaign)
    <<~PROMPT
      You are writing an ad for a #{brand.tone_of_voice} brand.
      
      Brand: #{brand.name}
      Product: #{campaign.product_name}
      Target Audience: #{campaign.target_audience}
      
      Write a compelling 2-sentence ad copy for social media.
      Focus on benefits, not features.
      Use a #{brand.tone_of_voice} tone.
    PROMPT
  end
end
```

### Step 3: Trigger Job from Controller
```ruby
# app/controllers/creatives_controller.rb
def create
  @creative = @campaign.creatives.build(creative_params)
  
  if @creative.save
    AdCopyGeneratorJob.perform_later(@creative.id)
    redirect_to @creative, notice: "Creative is being generated..."
  else
    render :new
  end
end
```

---

## Usage Pattern: Image Generation (TBD)

**NOTE:** We haven't decided on image provider yet. Use placeholder for now.

### Placeholder Implementation
```ruby
# app/jobs/background_image_generator_job.rb
class BackgroundImageGeneratorJob < ApplicationJob
  queue_as :default

  def perform(creative_id)
    creative = Creative.find(creative_id)
    
    # TODO: Replace with actual AI call when provider decided
    placeholder_url = generate_placeholder(creative)
    
    creative.raw_background.attach(
      io: URI.open(placeholder_url),
      filename: "background_#{creative.id}.png"
    )
    
    creative.update!(status: "background_generated")
  end

  private

  def generate_placeholder(creative)
    # Using placeholder service for now
    "https://placehold.co/1080x1080/#{creative.campaign.brand.primary_color.delete('#')}/white?text=AI+Generated"
  end
end
```

**When provider is decided, replace `generate_placeholder` with:**
```ruby
def generate_with_ai(creative)
  prompt = "A #{creative.campaign.product_description} in #{creative.campaign.style}"
  
  response = ImageGenerator.generate(
    prompt: prompt,
    size: "1080x1080",
    style: "photorealistic"
  )
  
  response.image_url
end
```

---

## Error Handling

### Retry Strategy
Solid Queue automatically retries failed jobs. Configure in model:
```ruby
class AdCopyGeneratorJob < ApplicationJob
  retry_on Langchain::LLM::ApiError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound  # Don't retry if record deleted
end
```

### User-Facing Errors
Store error state in `Creative` model:
```ruby
# db/migrate/..._add_error_to_creatives.rb
add_column :creatives, :error_message, :text
```

Display in view:
```erb
<% if @creative.failed? %>
  <div class="bg-red-50 p-4 rounded">
    <p class="font-bold">Generation failed:</p>
    <p><%= @creative.error_message %></p>
    <%= button_to "Retry", retry_creative_path(@creative), method: :post %>
  </div>
<% end %>
```

---

## Testing AI Calls (MVP Strategy)

### Don't Mock Everything
- **Integration tests:** Use real API (accept cost).
- **System tests:** Mock responses.

### Mock Example (RSpec)
```ruby
# spec/jobs/ad_copy_generator_job_spec.rb
RSpec.describe AdCopyGeneratorJob do
  it "generates ad copy" do
    creative = create(:creative)
    
    allow(Langchain.llm).to receive(:complete).and_return(
      double(completion: "Buy our amazing product!")
    )
    
    described_class.perform_now(creative.id)
    
    expect(creative.reload.ad_copy).to eq("Buy our amazing product!")
  end
end
```

---

## Cost Management

### Track API Usage
Add to `Creative` model:
```ruby
# db/migrate/..._add_ai_metadata_to_creatives.rb
add_column :creatives, :ai_tokens_used, :integer
add_column :creatives, :ai_cost_cents, :integer
```

Update in job:
```ruby
response = Langchain.llm.complete(prompt: prompt)

creative.update!(
  ad_copy: response.completion,
  ai_tokens_used: response.usage.total_tokens,
  ai_cost_cents: calculate_cost(response.usage)
)
```

### Set Budget Alerts
```ruby
# config/initializers/langchain.rb
Langchain.configure do |config|
  config.llm = Langchain::LLM::OpenAI.new(
    api_key: ...,
    max_tokens: 500,  # Prevent runaway costs
    timeout: 30       # Prevent hanging requests
  )
end
```

---

## Checklist Before Deploying AI Features
- [ ] API keys stored in `credentials.yml.enc` (not ENV vars).
- [ ] Jobs handle errors gracefully (retry logic + user feedback).
- [ ] Cost tracking enabled (tokens/cost columns).
- [ ] Timeout configured (prevent hanging requests).
- [ ] Tests use mocks (don't burn money in CI).

---

**When image provider is decided, update this skill file.**
