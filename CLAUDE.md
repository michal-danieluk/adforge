# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AdForge** is a Rails 8.0 SaaS application for generating AI-powered social media ads with strict brand consistency (colors, logos, fonts). The primary goal is to ship an MVP that can onboard 10 paying customers.

**Module Name:** `AdForge` (config/application.rb:9)

## Technology Stack

- **Framework:** Rails 8.0.2+ with Ruby 3.4.1
- **Database:** SQLite3 (production-ready, uses Solid Cache and Solid Queue)
- **Frontend:** Hotwire (Turbo + Stimulus) with Tailwind CSS via Propshaft
- **AI/ML:** `langchainrb` for provider abstraction, `ruby-openai` for LLM access
- **Image Processing:** `image_processing` with libvips backend (backend-first graphics)
- **Background Jobs:** Solid Queue (Rails 8 built-in)
- **Deployment:** Kamal with Docker (Thruster for serving)

**Important Constraints:**
- NO React/Vue/SPA frameworks (Hotwire only)
- NO feature flags, admin panels (ActiveAdmin/RailsAdmin), or drag-and-drop editors in MVP
- NO custom CSS files (Tailwind utilities only)

## Development Commands

### Setup
```bash
bundle install
rails db:migrate
```

### Running the Application
```bash
bin/dev                    # Start web server (port 20163, IPv6) + Tailwind watcher (via Procfile.dev)
rails server -b :: -p 20163  # Web server only on port 20163
rails tailwindcss:watch    # Tailwind CSS watcher
```

**Important**: After pulling changes that affect JavaScript/views:
- Hard refresh browser: `Ctrl+Shift+R` (Linux/Windows) or `Cmd+Shift+R` (Mac)
- Or clear cache and do a hard reload

### Testing
```bash
rails test                 # Run all tests
rails test:system          # Run system tests (Capybara + Selenium)
rails test test/models/model_name_test.rb       # Run specific test file
rails test test/models/model_name_test.rb:42    # Run specific test at line
```

### Code Quality
```bash
rubocop                    # Run linter (Omakase Ruby style)
rubocop -a                 # Auto-fix offenses
brakeman                   # Security vulnerability scanner
```

### Database
```bash
rails db:migrate           # Run pending migrations
rails db:rollback          # Rollback last migration
rails db:reset             # Drop, create, migrate, seed
```

### Scaffolding (Rapid Prototyping)
```bash
rails g scaffold Brand name:string tone_of_voice:string
rails g model BrandColor brand:references hex_value:string primary:boolean
rails g job AdCopyGenerator
rails db:migrate
```

## Architecture

### Three-Layer Model

1. **AI Layer (Generative)**
   - Generates raw backgrounds using image generation APIs (DALL-E/Flux - TBD)
   - Generates ad copy and CTAs using LLMs via `langchainrb`
   - Jobs: `AdCopyGeneratorJob`, `BackgroundImageGeneratorJob`

2. **Logic Layer (Rails)**
   - Manages project state and workflow
   - Core Models: `Brand`, `Campaign`, `Creative`
   - Background job orchestration via Solid Queue
   - State tracking (pending → generating → completed → failed)

3. **Composition Layer (Image Processing)**
   - Backend image manipulation using `image_processing` (libvips)
   - Overlays brand colors, typography, and logos onto AI-generated backgrounds
   - Ensures brand consistency across all generated creatives
   - NO client-side canvas manipulation

### Core Domain Models (Planned)

- **Brand:** Container for brand identity (colors, logos, fonts, tone)
  - `has_many :brand_colors, dependent: :destroy`
  - `has_one_attached :logo`
  - Attributes: name, tone_of_voice

- **Campaign:** Ad campaign tied to a brand
  - `belongs_to :brand`
  - `has_many :creatives, dependent: :destroy`
  - Attributes: product_name, target_audience, style

- **Creative:** Individual ad output
  - `belongs_to :campaign`
  - `has_one_attached :raw_background` (AI-generated)
  - `has_one_attached :final_image` (composed with brand assets)
  - Attributes: ad_copy, status, ai_tokens_used, ai_cost_cents, error_message

### Job Processing Pattern

All AI operations run asynchronously via Solid Queue:

```ruby
# In controller:
AdCopyGeneratorJob.perform_later(creative.id)

# Job implementation:
class AdCopyGeneratorJob < ApplicationJob
  retry_on Langchain::LLM::ApiError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(creative_id)
    creative = Creative.find(creative_id)
    # Generate content, update creative with results or error_message
  rescue => e
    creative.update!(status: "failed", error_message: e.message)
    raise
  end
end
```

## AI Integration Guidelines

**Golden Rule:** NEVER hardcode API calls directly. Always use `langchainrb` for provider abstraction.

### Configuration
- API keys stored in `rails credentials:edit` under `openai:api_key`, `dalle:api_key`, etc.
- LLM configuration in `config/initializers/langchain.rb`
- Cost tracking: store `ai_tokens_used` and `ai_cost_cents` on relevant models

### LLM Usage
```ruby
response = Langchain.llm.complete(prompt: prompt)
creative.update!(
  ad_copy: response.completion,
  ai_tokens_used: response.usage.total_tokens
)
```

### Image Generation (Provider TBD)
Use placeholder implementations until image generation provider is finalized. When implemented, swap placeholder logic with actual API calls via abstraction layer.

## Development Practices

### Scaffolding Workflow
1. Generate scaffold → Commit
2. Add model associations/validations → Commit
3. Update controller strong params → Commit
4. Style views with Tailwind → Commit
5. Write system test for CRUD → Commit

**Common Gotchas:**
- Always add `dependent: :destroy` to `has_many` associations
- Whitelist nested attributes in strong params: `nested_models_attributes: [:id, :field, :_destroy]`
- Avoid N+1 queries: use `.includes()` in index actions

### Git Workflow
- Commit after every meaningful change (15-30 min of work)
- Push to remote 2x per day minimum
- Work directly on `main` branch during MVP (no feature branches)
- Commit message format: `[Action] [What] [Why if not obvious]`
  - Good: `"Add BrandColor model with primary flag validation"`
  - Bad: `"updates"`, `"fix bug"`

### Testing Strategy (MVP)
- Test only critical paths (Brand creation, Campaign flow)
- **Integration tests:** Use real API (accept cost)
- **System tests:** Mock AI responses
- NO 100% coverage requirement in MVP phase

### Styling
- Tailwind utility classes ONLY (no custom CSS files, no inline styles)
- Use form helpers with Tailwind classes
- Keep views in ERB (no React components)

## Decision Framework

Before implementing any feature, ask:
1. Does this directly enable a paying customer?
2. Can it be simplified to 20% effort for 80% value?
3. Is this technically necessary or just "nice to have"?

If unsure → ask the human.

## Deployment

- **Method:** Kamal (Docker-based, config in `.kamal/`)
- **Web Server:** Thruster + Puma (exposed on port 80 in container)
- **SQLite Persistence:** Ensure data directory mounted as Docker volume
- **Production Config:** Solid Queue and Solid Cache must be properly configured
- **Health Check:** `/up` endpoint (rails/health#show)

## Security

- Store all secrets in `rails credentials:edit` (never in ENV vars or committed files)
- Brakeman for security scanning
- Avoid SQL injection, XSS, command injection (standard Rails protections apply)
- Never commit `.env`, `credentials.json`, or files with API keys

## Files to Avoid Modifying Without Cause

- `config/application.rb` (autoload paths, Rails config)
- `.rubocop.yml` (uses Omakase Ruby style)
- `Dockerfile` (optimized for Kamal deployment)
- `bin/*` (binstubs)

## Common Patterns

### Nested Forms (e.g., Brand with BrandColors)
```ruby
# Model
accepts_nested_attributes_for :brand_colors, allow_destroy: true

# Controller
def brand_params
  params.require(:brand).permit(
    :name,
    brand_colors_attributes: [:id, :hex_value, :primary, :_destroy]
  )
end

# View (use Stimulus for dynamic add/remove)
<%= form.fields_for :brand_colors do |color_fields| %>
  <%= color_fields.text_field :hex_value, class: "border rounded px-3 py-2" %>
  <%= color_fields.check_box :primary %>
  <%= color_fields.check_box :_destroy %>
<% end %>
```

### Error Display
```erb
<% if @creative.failed? %>
  <div class="bg-red-50 p-4 rounded">
    <p class="font-bold">Generation failed:</p>
    <p><%= @creative.error_message %></p>
    <%= button_to "Retry", retry_creative_path(@creative), method: :post %>
  </div>
<% end %>
```

### File Attachments
```ruby
# Model
has_one_attached :logo

# Migration
# (Active Storage tables created via rails active_storage:install)

# Controller
params.require(:brand).permit(:name, :logo)

# View
<%= form.file_field :logo, accept: "image/*", class: "..." %>
```

## Forbidden in MVP Phase

- Advanced authentication (Devise, MFA)
- Admin panels
- Real-time collaboration features
- Internationalization (i18n)
- Premature optimization (unless it breaks)
- Feature flags or backwards-compatibility shims
- Commented-out code, `binding.pry`, or `debugger` statements in commits
