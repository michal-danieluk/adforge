# ADFORGE MVP: BRAIN & VISUAL ENGINE SPECIFICATION

## 1. CONTEXT & TECH STACK (THE IRON RULES)
We are building AdForge, a SaaS for branded social media ads.
- **Framework:** Rails 8.0
- **DB:** SQLite (Production ready)
- **Background Jobs:** Solid Queue
- **Frontend:** Hotwire (Turbo/Stimulus) + TailwindCSS
- **AI Integration:** `langchainrb` (LLM abstraction) + `ruby-openai`
- **Image Processing:** `image_processing` (libvips)

## 2. ARCHITECTURE OVERVIEW: "THE TECH SANDWICH"
The generation process is split into two asynchronous phases:
1.  **Phase A (The Brain):** Generates strategy, copy, and image prompts (Text-only). Cheap & Fast.
2.  **Phase B (The Hands):** Generates images (DALL-E 3) and composes the final graphic (Libvips). Expensive & Slow.

---

## 3. PHASE A: IMPLEMENTING THE BRAIN (TEXT LAYER)

### 3.1. Database Changes
Update `Campaign` and `Creative` models:
- **Campaign:**
  - `status`: integer (enum: draft: 0, processing: 1, completed: 2, failed: 3)
- **Creative:**
  - `headline`: string
  - `body`: text
  - `background_prompt`: text
  - `status`: integer (enum: pending: 0, generated: 1, failed: 2)
  - `ai_metadata`: json (stores tokens, model used, cost)

### 3.2. Service Object: `Campaigns::GenerateConcepts`
- **Input:** `Campaign` instance.
- **Tool:** `Langchain::LLM::OpenAI` (Model: `gpt-4o-mini`).
- **Logic:**
  1. Construct a prompt using Brand info (Voice) and Campaign info (Topic, Audience).
  2. Request strictly formatted JSON output containing 3 distinct ad concepts.
  3. JSON Structure: `[{ "headline": "...", "body": "...", "background_prompt": "..." }]`.
  4. **Validation:** Ensure valid JSON is returned.
  5. **Persistence:** Create 3 `Creative` records associated with the campaign.
- **Output:** Array of created Creatives.

### 3.3. Job: `GenerateCampaignJob`
- **Trigger:** User clicks "Generate" on Campaign Show page.
- **Action:**
  1. Set Campaign status to `processing`.
  2. Broadcast Turbo Stream (spinner).
  3. Call `Campaigns::GenerateConcepts`.
  4. On Success: Set status `completed`. Trigger `RenderCreativeJob` for each new creative (see Phase B).
  5. On Fail: Set status `failed`, log error.

---

## 4. PHASE B: IMPLEMENTING THE VISUAL ENGINE (GRAPHICS LAYER)

### 4.1. Prerequisites
- Ensure `image_processing` gem is installed.
- Ensure `ruby-openai` is configured for DALL-E 3.

### 4.2. Service Object: `Creatives::GenerateImage`
- **Input:** `Creative` instance.
- **Action 1 (AI Generation):**
  - Call OpenAI DALL-E 3 API using `creative.background_prompt`.
  - Download the resulting image to a temp file.
- **Action 2 (Composition - The Secret Sauce):**
  - Use `ImageProcessing::Vips`.
  - Resize background to 1080x1080 (smart crop).
  - **Apply Overlay:** Add a semi-transparent layer of `Brand#primary_color` (opacity ~30-50%) to ensure text readability.
  - **Add Text:** Render `creative.headline` (Bold, Large) and `creative.body` (Regular, Small) using white text with drop-shadow. *Note: Keep it simple for MVP - center text or bottom align.*
  - **Add Logo:** Composite `Brand#logo` (if attached) in the corner (watermark style).
- **Persistence:** Attach the final composited image to `Creative#final_image` (ActiveStorage).
- **Metadata:** Update `ai_metadata` with image generation cost.

### 4.3. Job: `RenderCreativeJob`
- **Queue:** `default` (Solid Queue).
- **Input:** `creative_id`.
- **Logic:**
  1. Check if creative already has an image (idempotency).
  2. Call `Creatives::GenerateImage`.
  3. Broadcast Turbo Stream update to replace the placeholder in the UI with the final image.

---

## 5. UI/UX GUIDELINES (HOTWIRE)
- **Campaign Show View:**
  - Must use `<%= turbo_stream_from @campaign %>`.
  - Display a grid of Creatives.
  - While processing Phase A: Show a global spinner/loader.
  - While processing Phase B: Show skeleton/placeholder for each creative card until the image arrives via Turbo.

---

## 6. EXECUTION PLAN FOR CLAUDE
1. **Analyze** current database schema and installed gems.
2. **Implement Phase A** (Migrations, Service, Job, View updates).
3. **Verify Phase A** (Ensure JSON parsing works and records are created).
4. **Implement Phase B** (DALL-E integration, Libvips composition).
5. **Verify Phase B** (Ensure images are attached and displayed).
