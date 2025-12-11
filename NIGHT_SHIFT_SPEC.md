# ADFORGE: NIGHT SHIFT SPECIFICATION (v1.0) - COMPLETE

## 1. META-INSTRUCTIONS & ROLES
**ACT AS:** A fusion of a Senior Ruby Architect (CTO), a Growth Hacker, and a Lead UI/UX Designer.
**GOAL:** Execute a massive overhaul of the UI, Security, and Core Logic autonomously.
**CONSTRAINT:** Use Tailwind CSS only. FLAT COLORS (Zinc, Slate, Neutral + Indigo/Orange for accents). NO GRADIENTS. Style: "Swiss Utility" / Linear-like.
**STACK:** Ruby on Rails 8.0, SQLite, Hotwire (Turbo/Stimulus), Solid Queue.

---

## 2. PHASE 1: SECURITY & ROLES (PRIORITY ZERO)
**Context:** Currently, the API Key settings are exposed to everyone. This is a security risk.
**Task:** Implement Role-Based Access Control (RBAC) to protect the Settings.

### 2.1. Database Update
- Add `role` column to `users` table (integer, default: 0).
- Define Enum in `User` model: `enum :role, { user: 0, admin: 1 }`.
- **Migration logic:** Ensure the *first* user in the database (ID: 1) is automatically updated to `role: :admin`.

### 2.2. Admin Namespace
- Move `SettingsController` to `Admin::SettingsController`.
- Update Routes:
  ```ruby
  namespace :admin do
    resource :settings, only: [:show, :update]
    get 'dashboard', to: 'dashboard#index'
  end
Controller Guard: Add before_action :require_admin! to Admin::BaseController (create this parent controller).

Navigation: The "⚙️ Settings" link in the sidebar/navbar must ONLY be visible if Current.user&.admin?.

3. PHASE 2: CORE LOGIC - THE "MODEL SWITCHER"
Task: Finalize the Creatives::GenerateImage service to support multiple AI models via AppConfig.

3.1. AppConfig Model
Ensure AppConfig has:

gemini_api_key (text, encrypted via encrypts).

ai_model (string, default: "gemini-2.0-flash-exp").

3.2. Service Logic Refactor
Refactor Creatives::GenerateImage to switch logic based on AppConfig.first.ai_model:

CASE A: imagen-3.0-generate-001 (Premium)

URL: https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict

Body: { instances: [{ prompt: creative.background_prompt }], parameters: { sampleCount: 1, aspectRatio: "1:1" } }

Response Path: json['predictions'][0]['bytesBase64Encoded']

CASE B: gemini-2.0-flash-exp (Fast/Free)

URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent

Body: { contents: [{ parts: [{ text: "Generate a high quality image: " + creative.background_prompt }] }] }

Response Path: json['candidates'][0]['content']['parts'][0]['inlineData']['data']

ERROR HANDLING:

Wrap requests in begin/rescue.

If 429 Too Many Requests: Update creative.ai_metadata with error and set status to failed. Do not crash the job.

4. PHASE 3: UI/UX OVERHAUL (SWISS UTILITY)
Designer Persona: Minimalism, whitespace, perfect alignment.

4.1. Global Layout (layouts/application.html.erb)
Sidebar (Left, Fixed, w-64):

Background: bg-zinc-50 border-r border-zinc-200.

Logo area: Simple text "AdForge" (font-bold text-xl tracking-tight).

Nav Links: Dashboard, Campaigns, History. Use text-zinc-500 hover:text-zinc-900. Active state: bg-white shadow-sm text-zinc-900.

Main Content: bg-white (or very light gray).

4.2. Campaign Index (Dashboard)
Header: "Your Campaigns" + "New Campaign" button (Primary Color: bg-indigo-600).

Grid: grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6.

Card Design:

Border: border border-zinc-200 rounded-lg.

Shadow: hover:shadow-md transition-shadow.

Content: Topic (Bold), Date (Gray), Status Badge (Pill shape).

4.3. Creative Card (The Result)
Image: Square aspect ratio. If loading: Skeleton pulse (animate-pulse bg-zinc-200).

Text: Display Headline below image in font-medium text-zinc-900.

Actions: "Download" (Secondary button), "Render" (if not generated).

5. PHASE 4: LANDING PAGE (MARKETING)
Task: Replace the generic root with a high-converting Homepage for logged-out users.

5.1. Copy & Structure
Hero Section:

H1: "Create On-Brand Ads in Seconds."

Sub: "Stop wrestling with Canva. Let AI generate professional social media creatives that respect your logo and colors."

CTA: "Start Building Free" -> Links to Registration.

Social Proof: "Powered by Gemini 2.0 Flash & Imagen 3".

Features Grid:

"Brand Safe": We lock your colors and fonts.

"AI Copywriter": Headlines that convert.

"Visual Engine": Tweak layouts instantly.

6. PHASE 5: NEW FEATURE - CONTENT REFINEMENT
User Story: "The headline is okay, but I want a variation."

6.1. "Magic Rewrite"
Add a button ✨ Rewrite next to the Headline on the Creative card.

Controller: POST /creatives/:id/rewrite.

Logic:

Call Gemini Flash API.

Prompt: "Rewrite this ad headline to be more punchy/viral: '#{current_headline}'. Max 6 words."

Update the record.

Return Turbo Stream to replace the text in-place.

7. EXECUTION CHECKLIST FOR AGENT
Follow this sequence strictly:

[ ] Security: Run migration for Users (role) & AppConfig. Create Admin Controller.

[ ] Backend: Implement the GenerateImage service with the switch statement.

[ ] Frontend: Apply the Tailwind Sidebar layout and Card styles.

[ ] Marketing: Create the Landing Page view.

[ ] Feature: Implement the "Magic Rewrite" endpoint and button.

[ ] Verify: Ensure no API keys are hardcoded in views.

FINISH CONDITION: All 5 phases are implemented, code is clean, and the server starts without errors.












