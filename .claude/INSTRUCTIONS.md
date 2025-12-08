# AdForge - Project Instructions for Claude Code

## PROJECT OVERVIEW
AdForge is a SaaS tool for generating AI-powered social media ads with strict brand consistency (colors, logos, fonts). 

**Business Goal:** Ship MVP in 2 weeks. First 10 paying customers.

**Your Role:** Build fast, test critical paths, ship iteratively. You are NOT building a perfect system – you're building a **money-making machine**.

---

## TECHNICAL STACK (NON-NEGOTIABLE)
- **Rails:** 8.0 (Solid Queue, Solid Cache)
- **Database:** SQLite (production-ready, persisted in Docker volume)
- **Frontend:** Hotwire (Turbo + Stimulus) + Tailwind CSS + Propshaft
- **AI/LLM:** `langchainrb` (provider-agnostic: OpenAI, Claude, Gemini)
- **Graphics:** `image_processing` (libvips backend) – NO client-side canvas
- **Deploy:** Kamal (Docker)

**ABSOLUTE BANS:**
- ❌ React/Vue/Next.js
- ❌ PostgreSQL/MySQL (SQLite only)
- ❌ Webpacker/esbuild (Propshaft only)

---

## ARCHITECTURE (3-LAYER MODEL)

This is the mental model you MUST respect:
```
┌─────────────────────────────────────────────────────┐
│  LAYER 1: AI (Generative)                          │
│  - Generates raw backgrounds (DALL-E/Flux/etc)     │
│  - Generates ad copy (GPT/Claude/Gemini)           │
│  - Provider: TBD (use langchainrb for flexibility) │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  LAYER 2: Logic (Rails)                            │
│  - Manages state: Brand → Campaign → Creative      │
│  - Queues jobs (Solid Queue)                       │
│  - Stores metadata (SQLite)                        │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  LAYER 3: Composition (Image Processing)           │
│  - Takes raw background from AI                    │
│  - Overlays brand colors (hex overlay)             │
│  - Renders typography (brand fonts)                │
│  - Adds logo (positioned via rules)                │
│  - Outputs final PNG/JPEG                          │
└─────────────────────────────────────────────────────┘
```

**Core Models (DO NOT ADD MORE IN MVP):**
1. `Brand` (name, tone_of_voice, logo)
   - `has_many :brand_colors`
   - `has_many :campaigns`
2. `BrandColor` (hex_value, primary:boolean)
3. `Campaign` (product_name, target_audience)
   - `belongs_to :brand`
   - `has_many :creatives`
4. `Creative` (generated_image, ad_copy, status)
   - `belongs_to :campaign`

---

## CODE PRINCIPLES

### 1. LLM Agnostic
- ALWAYS use `langchainrb` gem for AI calls.
- NEVER hardcode OpenAI/Claude API directly.
- Reason: We don't know which AI provider we'll use for image generation yet. Must be swappable.

### 2. Backend-First Graphics
- Use `image_processing` (libvips) for ALL image operations.
- NO JavaScript canvas manipulation.
- NO drag-and-drop editors in MVP.

### 3. No Feature Creep
Before implementing ANY feature, ask:
1. **Does this directly enable a paying customer?**
2. **Can I deliver 80% value with 20% effort?**
3. **Is this technically required or just "nice to have"?**

If answer to #1 is NO → **REJECT IT**.

### 4. Git Discipline (CRITICAL)
- Commit **after every meaningful change** (every 15-30 min of work).
- Use descriptive messages: `git commit -m "Add BrandColor model with primary flag validation"`
- **NEVER** work for 2+ hours without committing.
- Push to remote **at least 2x per day**.

### 5. Test Philosophy (MVP)
- Test ONLY critical user paths.
- Example: "User creates Brand → uploads logo → sees it in list" = 1 system test.
- NO unit tests for helpers/concerns in MVP.
- NO 100% coverage requirement.

---

## FORBIDDEN FEATURES (MVP Phase)

These will KILL your 2-week deadline:

- ❌ Advanced authentication (Devise multi-factor, OAuth)
- ❌ Admin panels (ActiveAdmin, RailsAdmin)
- ❌ Drag-and-drop visual editors
- ❌ Real-time collaboration (Action Cable, WebSockets)
- ❌ Internationalization (i18n/l10n)
- ❌ SQL query optimization (unless it actually breaks)
- ❌ API versioning (just `/api/v1/...` is fine)
- ❌ Background job dashboards (Sidekiq Web, etc.)

If I suggest ANY of the above → **REFUSE** and propose simpler alternative.

---

## DECISION FRAMEWORK

When uncertain about implementation:

1. **Check if it's in FORBIDDEN list** → If yes, reject.
2. **Estimate effort** → If >4 hours, ask human for approval.
3. **Check if Rails convention exists** → Use scaffold/generator first.
4. **Simplify** → Can you cut 50% of the feature and still deliver value?

---

## DEPLOYMENT STRATEGY

- **Local Dev:** `rails s` (SQLite in `storage/` directory)
- **Production:** Kamal + Docker
  - SQLite data MUST persist in named volume: `/rails/storage`
  - Solid Queue runs in same container (no separate Redis)
  - Solid Cache uses SQLite (no memcached)

**Deploy Checklist:**
- [ ] `config/database.yml` uses SQLite for production
- [ ] `Dockerfile` includes libvips
- [ ] Kamal `deploy.yml` mounts persistent volume
- [ ] Secrets stored in `config/credentials.yml.enc`

---

## CODING STYLE

- **Prefer Rails conventions** over custom abstractions.
- **Use generators** (`rails g scaffold`, `rails g model`).
- **Keep controllers thin** – move complex logic to models or jobs.
- **Jobs for async work** – AI calls, image processing (never in controller).
- **Naming:** `BrandColorValidator` not `ColorChecker`, `AdCopyGeneratorJob` not `TextMaker`.

---

## GIT WORKFLOW (MANDATORY)
```bash
# After every feature/fix:
git add .
git commit -m "Descriptive message explaining WHAT and WHY"
git push origin main

# Before starting new task:
git pull origin main

# If stuck for >30 min:
git commit -m "WIP: [describe problem]"
git push origin main
# Then ask human for help
```

**Commit Message Rules:**
- ✅ "Add BrandColor model with hex validation"
- ✅ "Fix logo upload failing for SVG files"
- ✅ "Refactor Campaign form to use nested attributes"
- ❌ "updates"
- ❌ "fix bug"
- ❌ "wip"

---

## WHEN TO ASK HUMAN

- Feature seems too complex for MVP (>8 hours estimated).
- Unsure which AI provider to use (we haven't decided yet).
- Deployment config unclear (Kamal setup).
- Business logic ambiguous (e.g., "What happens if user uploads 0 colors?").
- You've been stuck on same problem for 45+ minutes.

**How to Ask:**
```
BLOCKED: [Brief description of problem]
CONTEXT: [What you tried]
OPTIONS: [2-3 possible solutions with pros/cons]
RECOMMENDATION: [Your preferred option + why]
```

---

## SUCCESS METRICS (MVP)

You've succeeded when:
- [ ] User can create Brand (name, colors, logo, tone).
- [ ] User can create Campaign (product, audience).
- [ ] User can generate 1 Creative (mocked AI for now).
- [ ] User can download generated image.
- [ ] App deployed to production (Kamal).
- [ ] Basic Stripe checkout works (single plan: $29/mo).

**NOT required for MVP:**
- User accounts (we'll add basic auth in Iteration 2).
- Email notifications.
- Analytics dashboard.
- Mobile responsiveness (desktop-first).

---

**Last Updated:** 2025-12-08  
**Current Iteration:** 1 (Brand + BrandColor models)
