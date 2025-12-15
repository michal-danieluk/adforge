# ADFORGE: NIGHT SHIFT MASTER PLAN (v3.0 - POLISH EDITION)

## 1. META-INSTRUCTIONS & ROLES
**ACT AS:** An autonomous Squad Lead consisting of:
1.  **Backend Architect (CTO):** Focus on data integrity, API connections, and bug fixes.
2.  **Native Polish Copywriter:** All user-facing text MUST be in professional Polish.
3.  **UI/UX Designer:** Focus on Mobile responsiveness and "Swiss Utility" aesthetics.

**GOAL:** By morning, the application must be STABLE, RESPONSIVE, and fully translated to POLISH.
**CONSTRAINT:** Use Rails `i18n` where possible, or hardcode Polish text if faster for MVP. No English text should remain in the UI.

---

## 2. PHASE 1: CRITICAL BUGFIXES (STABILITY FIRST)

### 2.1. Fix "Empty History" (Priority Zero)
**Symptom:** Campaigns are not showing up in the index view.
**Tasks:**
1.  **Association Check:** Verify `Campaign` belongs to `User` and `User` has many `Campaigns`.
2.  **Controller Audit:** Ensure `CampaignsController#create` correctly assigns `current_user`.
3.  **Scope Fix:** Ensure `CampaignsController#index` fetches `Current.user.campaigns.order(created_at: :desc)`.

### 2.2. Deep Image Rendering Audit
**Tasks:**
1.  **Service Fix (`Creatives::GenerateImage`):**
    - Ensure `AppConfig` correctly switches between `gemini-2.0-flash-exp` and `imagen-3.0`.
    - Handle API errors gracefully (save error message to `ai_metadata`, set status to `failed`).
2.  **UI Feedback:** If a creative fails, show a red badge "Błąd Generowania" instead of infinite spinner.

---

## 3. PHASE 2: LOCALIZATION (POLONIZACJA) 🇵🇱
**Context:** The application is currently mixed/English. It must be 100% Polish.

### 3.1. Rails Configuration
- Set `config.i18n.default_locale = :pl` in `application.rb`.
- Create `config/locales/pl.yml` with translations for:
  - ActiveRecord models (attributes: Name -> Nazwa, Topic -> Temat, etc.).
  - Flash messages (Success -> Sukces, Error -> Błąd).
  - Time formats (standard Polish date format).

### 3.2. View Translation (Sweep)
Iterate through ALL views (`app/views/**/*`) and translate UI text:
- "Dashboard" -> "Pulpit"
- "Campaigns" -> "Kampanie"
- "Settings" -> "Ustawienia"
- "Generate" -> "Generuj"
- "Download" -> "Pobierz"
- "Status: Draft" -> "Szkic"
- "Status: Processing" -> "Przetwarzanie"
- "Status: Completed" -> "Gotowe"

---

## 4. PHASE 3: MOBILE & UI OVERHAUL (DESIGNER)

### 4.1. Responsive Navigation
- **Desktop (`lg:`):** Fixed left sidebar (`w-64`, `bg-zinc-50`).
- **Mobile (`< lg`):**
  - Implement a Top Navbar with a "Hamburger" icon.
  - Clicking the icon opens a Slide-over menu (use Stimulus or simple CSS toggle).
  - Ensure "Ustawienia" and "Wyloguj" are accessible on mobile.

### 4.2. Grid Layouts & Cards
- **Campaigns List:** `grid-cols-1` (Mobile) -> `sm:grid-cols-2` -> `lg:grid-cols-3`.
- **Creative Cards:** Ensure full width on mobile, proper aspect ratio (square).
- **Style:** "Swiss Utility". White cards, thin gray borders (`border-zinc-200`), distinct black/indigo buttons. No gradients.

---

## 5. PHASE 4: UX DELIGHT & "EMPTY STATES"

### 5.1. Empty States (Puste Stany)
**Context:** Don't show empty tables.
- **Campaigns:** If `current_user.campaigns.empty?`:
  - Show a centered component.
  - Icon: Folder/Plus.
  - Text: "Nie masz jeszcze żadnych kampanii."
  - Subtext: "Stwórz swoją pierwszą reklamę w 30 sekund."
  - Button: "Nowa Kampania" (Primary).

### 5.2. Toast Notifications (Powiadomienia)
- Replace default Rails flash messages with a "Toast" component (bottom-right).
- Style:
  - `notice` -> Green border/text ("Sukces").
  - `alert` -> Red border/text ("Błąd").
- auto-dismiss after 4 seconds.

### 5.3. "Magic Rewrite" (Magiczna Korekta)
- In the Creative Card, verify the "✨ Popraw" (Rewrite) button works.
- It should call Gemini Flash to rewrite the Polish headline to be more "viral".

---

## 6. PHASE 5: LANDING PAGE & SEO (MARKETING)

### 6.1. Homepage (`Pages#home`)
**Translate and Optimize for Polish Market:**
- **Hero:**
  - H1: "Generuj Profesjonalne Reklamy w Sekundy."
  - Sub: "Twoje logo, Twoje kolory, Twoja marka. AI zadba o resztę."
  - CTA: "Rozpocznij za Darmo".
- **Features:**
  - "Zgodność z Marką" (Brand Consistency).
  - "Polska AI" (Supports Polish language generation).
  - "Szybki Export" (Ready for Instagram/Facebook).
- **Footer:** Links to "Regulamin", "Prywatność", "Kontakt". Copyright 2025.

### 6.2. SEO Tags
- Title: `AdForge - Generator Reklam AI dla Polskich Marek`
- Description: `Twórz grafiki reklamowe zgodne z identyfikacją wizualną Twojej firmy.`

---

## 7. EXECUTION CHECKLIST (STRICT ORDER)
1.  **[CRITICAL]** Fix `User <-> Campaign` association bug. (Make sure History works).
2.  **[BACKEND]** Finalize Image Service (Flash/Imagen) & Error Handling.
3.  **[LOCALIZATION]** **Translate the entire app to Polish.** (Do this before styling to check text length).
4.  **[FRONTEND]** Apply Mobile/Tablet responsive layout.
5.  **[UX]** Implement Empty States & Toasts.
6.  **[MARKETING]** Build the Polish Landing Page.
7.  **[VERIFICATION]** Run `bin/rails db:seed` (create Polish sample data) and verify the app runs without errors.

*Start working. The output must be production-ready and fully in Polish.*# ADFORGE: NIGHT SHIFT MASTER PLAN (v3.0 - POLISH EDITION)

## 1. META-INSTRUCTIONS & ROLES
**ACT AS:** An autonomous Squad Lead consisting of:
1.  **Backend Architect (CTO):** Focus on data integrity, API connections, and bug fixes.
2.  **Native Polish Copywriter:** All user-facing text MUST be in professional Polish.
3.  **UI/UX Designer:** Focus on Mobile responsiveness and "Swiss Utility" aesthetics.

**GOAL:** By morning, the application must be STABLE, RESPONSIVE, and fully translated to POLISH.
**CONSTRAINT:** Use Rails `i18n` where possible, or hardcode Polish text if faster for MVP. No English text should remain in the UI.

---

## 2. PHASE 1: CRITICAL BUGFIXES (STABILITY FIRST)

### 2.1. Fix "Empty History" (Priority Zero)
**Symptom:** Campaigns are not showing up in the index view.
**Tasks:**
1.  **Association Check:** Verify `Campaign` belongs to `User` and `User` has many `Campaigns`.
2.  **Controller Audit:** Ensure `CampaignsController#create` correctly assigns `current_user`.
3.  **Scope Fix:** Ensure `CampaignsController#index` fetches `Current.user.campaigns.order(created_at: :desc)`.

### 2.2. Deep Image Rendering Audit
**Tasks:**
1.  **Service Fix (`Creatives::GenerateImage`):**
    - Ensure `AppConfig` correctly switches between `gemini-2.0-flash-exp` and `imagen-3.0`.
    - Handle API errors gracefully (save error message to `ai_metadata`, set status to `failed`).
2.  **UI Feedback:** If a creative fails, show a red badge "Błąd Generowania" instead of infinite spinner.

---

## 3. PHASE 2: LOCALIZATION (POLONIZACJA) 🇵🇱
**Context:** The application is currently mixed/English. It must be 100% Polish.

### 3.1. Rails Configuration
- Set `config.i18n.default_locale = :pl` in `application.rb`.
- Create `config/locales/pl.yml` with translations for:
  - ActiveRecord models (attributes: Name -> Nazwa, Topic -> Temat, etc.).
  - Flash messages (Success -> Sukces, Error -> Błąd).
  - Time formats (standard Polish date format).

### 3.2. View Translation (Sweep)
Iterate through ALL views (`app/views/**/*`) and translate UI text:
- "Dashboard" -> "Pulpit"
- "Campaigns" -> "Kampanie"
- "Settings" -> "Ustawienia"
- "Generate" -> "Generuj"
- "Download" -> "Pobierz"
- "Status: Draft" -> "Szkic"
- "Status: Processing" -> "Przetwarzanie"
- "Status: Completed" -> "Gotowe"

---

## 4. PHASE 3: MOBILE & UI OVERHAUL (DESIGNER)

### 4.1. Responsive Navigation
- **Desktop (`lg:`):** Fixed left sidebar (`w-64`, `bg-zinc-50`).
- **Mobile (`< lg`):**
  - Implement a Top Navbar with a "Hamburger" icon.
  - Clicking the icon opens a Slide-over menu (use Stimulus or simple CSS toggle).
  - Ensure "Ustawienia" and "Wyloguj" are accessible on mobile.

### 4.2. Grid Layouts & Cards
- **Campaigns List:** `grid-cols-1` (Mobile) -> `sm:grid-cols-2` -> `lg:grid-cols-3`.
- **Creative Cards:** Ensure full width on mobile, proper aspect ratio (square).
- **Style:** "Swiss Utility". White cards, thin gray borders (`border-zinc-200`), distinct black/indigo buttons. No gradients.

---

## 5. PHASE 4: UX DELIGHT & "EMPTY STATES"

### 5.1. Empty States (Puste Stany)
**Context:** Don't show empty tables.
- **Campaigns:** If `current_user.campaigns.empty?`:
  - Show a centered component.
  - Icon: Folder/Plus.
  - Text: "Nie masz jeszcze żadnych kampanii."
  - Subtext: "Stwórz swoją pierwszą reklamę w 30 sekund."
  - Button: "Nowa Kampania" (Primary).

### 5.2. Toast Notifications (Powiadomienia)
- Replace default Rails flash messages with a "Toast" component (bottom-right).
- Style:
  - `notice` -> Green border/text ("Sukces").
  - `alert` -> Red border/text ("Błąd").
- auto-dismiss after 4 seconds.

### 5.3. "Magic Rewrite" (Magiczna Korekta)
- In the Creative Card, verify the "✨ Popraw" (Rewrite) button works.
- It should call Gemini Flash to rewrite the Polish headline to be more "viral".

---

## 6. PHASE 5: LANDING PAGE & SEO (MARKETING)

### 6.1. Homepage (`Pages#home`)
**Translate and Optimize for Polish Market:**
- **Hero:**
  - H1: "Generuj Profesjonalne Reklamy w Sekundy."
  - Sub: "Twoje logo, Twoje kolory, Twoja marka. AI zadba o resztę."
  - CTA: "Rozpocznij za Darmo".
- **Features:**
  - "Zgodność z Marką" (Brand Consistency).
  - "Polska AI" (Supports Polish language generation).
  - "Szybki Export" (Ready for Instagram/Facebook).
- **Footer:** Links to "Regulamin", "Prywatność", "Kontakt". Copyright 2025.

### 6.2. SEO Tags
- Title: `AdForge - Generator Reklam AI dla Polskich Marek`
- Description: `Twórz grafiki reklamowe zgodne z identyfikacją wizualną Twojej firmy.`

---

## 7. EXECUTION CHECKLIST (STRICT ORDER)
1.  **[CRITICAL]** Fix `User <-> Campaign` association bug. (Make sure History works).
2.  **[BACKEND]** Finalize Image Service (Flash/Imagen) & Error Handling.
3.  **[LOCALIZATION]** **Translate the entire app to Polish.** (Do this before styling to check text length).
4.  **[FRONTEND]** Apply Mobile/Tablet responsive layout.
5.  **[UX]** Implement Empty States & Toasts.
6.  **[MARKETING]** Build the Polish Landing Page.
7.  **[VERIFICATION]** Run `bin/rails db:seed` (create Polish sample data) and verify the app runs without errors.

*Start working. The output must be production-ready and fully in Polish.*
