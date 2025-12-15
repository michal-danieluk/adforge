# Generowanie Grafiki i Tekstu z AI - Dokumentacja Techniczna

## Spis treści
1. [Architektura systemu](#architektura-systemu)
2. [Generowanie tekstu (LLM)](#generowanie-tekstu-llm)
3. [Generowanie obrazów](#generowanie-obrazów)
4. [Przepływ danych](#przepływ-danych)
5. [Najczęstsze błędy i ich rozwiązania](#najczęstsze-błędy-i-ich-rozwiązania)
6. [Checklist przed implementacją](#checklist-przed-implementacją)
7. [Konfiguracja modeli](#konfiguracja-modeli)

---

## Architektura systemu

### Dwuetapowy proces generowania

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Użytkownik    │────▶│  Generuj tekst  │────▶│  Generuj obraz  │
│   tworzy        │     │  (GPT-4o-mini)  │     │  (Gemini 2.5)   │
│   creative      │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                       │
                               ▼                       ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │ headline        │     │ final_image     │
                        │ body            │     │ (załącznik)     │
                        │ background_prompt│     │                 │
                        └─────────────────┘     └─────────────────┘
```

### Kluczowe pliki

| Plik | Odpowiedzialność |
|------|------------------|
| `app/jobs/creative_generator_job.rb` | Orkiestracja - najpierw tekst, potem obraz |
| `app/services/creatives/generate_image.rb` | Generowanie obrazów przez Gemini/Imagen |
| `app/services/campaigns/generate_concepts.rb` | Generowanie wielu koncepcji naraz |
| `app/jobs/render_creative_job.rb` | Wrapper na GenerateImage |
| `config/initializers/langchain.rb` | Konfiguracja klienta LLM |

---

## Generowanie tekstu (LLM)

### Używany model
- **OpenAI GPT-4o-mini** - szybki, tani, dobry do copywritingu
- Biblioteka: `langchainrb` (abstrakcja nad różnymi providerami)

### Konfiguracja klienta

```ruby
# config/initializers/langchain.rb
Rails.application.config.langchain_llm = Langchain::LLM::OpenAI.new(
  api_key: Rails.application.credentials.dig(:openai, :api_key),
  default_options: { temperature: 0.7 }
)
```

### Wywołanie API

```ruby
llm = Rails.application.config.langchain_llm

response = llm.chat(
  messages: [{ role: "user", content: prompt }],
  model: "gpt-4o-mini",
  temperature: 0.7,
  response_format: { type: "json_object" }  # Wymusza JSON
)

# Parsowanie odpowiedzi
parsed = JSON.parse(response.completion)
headline = parsed["headline"]
body = parsed["body"]
background_prompt = parsed["background_prompt"]

# Dostęp do metadanych (UWAGA na API!)
tokens = response.total_tokens        # NIE response.usage["total_tokens"]
prompt_tokens = response.prompt_tokens
completion_tokens = response.completion_tokens
```

### Struktura promptu

```ruby
<<~PROMPT
  Jesteś ekspertem copywritingu reklamowego dla marki "#{brand.name}".
  Ton komunikacji marki: "#{brand.tone_of_voice}".

  Wygeneruj JEDNĄ koncepcję reklamową.

  Szczegóły kampanii:
  Produkt: #{campaign.product_name}
  Grupa docelowa: #{campaign.target_audience}
  Opis: #{campaign.description}

  WAŻNE:
  - headline i body w języku POLSKIM
  - background_prompt w języku ANGIELSKIM (dla generatora obrazów!)
  - headline: max 8 słów
  - body: 1-2 zdania
  - background_prompt: szczegółowy opis wizualny

  Zwróć JSON:
  {
    "headline": "...",
    "body": "...",
    "background_prompt": "..."
  }
PROMPT
```

---

## Generowanie obrazów

### Dostępne modele Google

| Model | Endpoint | Metoda | Uwagi |
|-------|----------|--------|-------|
| `gemini-2.5-flash-image` | generateContent | POST | **ZALECANY** - wymaga `responseModalities: ["IMAGE"]` |
| `imagen-4.0-generate-001` | predict | POST | Premium jakość, droższy |
| `gemini-2.0-flash-exp` | generateContent | POST | **NIE GENERUJE OBRAZÓW** - tylko tekst! |

### Kluczowa konfiguracja dla Gemini 2.5

```ruby
def generate_with_gemini(api_key)
  conn = Faraday.new(url: "https://generativelanguage.googleapis.com") do |f|
    f.headers["x-goog-api-key"] = api_key
    f.headers["Content-Type"] = "application/json"
  end

  # KRYTYCZNE: Użyj modelu z "-image" w nazwie!
  response = conn.post("/v1beta/models/gemini-2.5-flash-image:generateContent") do |req|
    req.body = {
      contents: [{ parts: [{ text: background_prompt }] }],
      generationConfig: {
        responseModalities: ["IMAGE"]  # WYMAGANE dla generowania obrazów!
      }
    }.to_json
  end

  # Parsowanie odpowiedzi - szukaj inlineData
  response_body = JSON.parse(response.body)
  parts = response_body.dig('candidates', 0, 'content', 'parts') || []
  image_part = parts.find { |p| p['inlineData'].present? }

  if image_part.nil?
    raise "API returned no image data"
  end

  Base64.decode64(image_part['inlineData']['data'])
end
```

### Konfiguracja dla Imagen 4

```ruby
def generate_with_imagen(api_key)
  response = conn.post("/v1beta/models/imagen-4.0-generate-001:predict") do |req|
    req.body = {
      instances: [{ prompt: background_prompt }],
      parameters: {
        sampleCount: 1,
        aspectRatio: "1:1"
      }
    }.to_json
  end

  response_body = JSON.parse(response.body)
  Base64.decode64(response_body['predictions'][0]['bytesBase64Encoded'])
end
```

### Przetwarzanie obrazu

```ruby
require "image_processing/vips"

def process_and_attach(raw_image_data, creative)
  Tempfile.open(["raw", ".png"], binmode: true) do |raw_file|
    raw_file.write(raw_image_data)
    raw_file.rewind

    # Skalowanie do 1080x1080
    processed = ImageProcessing::Vips
                  .source(raw_file.path)
                  .resize_to_fill(1080, 1080)
                  .call

    creative.final_image.attach(
      io: File.open(processed.path),
      filename: "creative_#{creative.id}.png",
      content_type: "image/png"
    )

    creative.update!(status: :generated)
  end
end
```

---

## Przepływ danych

### Kolejność operacji (KRYTYCZNA!)

```ruby
class CreativeGeneratorJob < ApplicationJob
  def perform(creative_id)
    creative = Creative.find(creative_id)

    # KROK 1: Najpierw generuj TEKST
    generate_ad_copy(creative)

    # KROK 2: Dopiero potem generuj OBRAZ
    # (obraz potrzebuje background_prompt który jest generowany w kroku 1)
    RenderCreativeJob.perform_later(creative.id)
  end
end
```

### Walidacja przed generowaniem obrazu

```ruby
def call
  # ZAWSZE sprawdź czy prompt istnieje!
  if @creative.background_prompt.blank?
    raise StandardError.new("Brak promptu do generowania obrazu")
  end

  # ... reszta logiki
end
```

---

## Najczęstsze błędy i ich rozwiązania

### 1. Model zwraca tekst zamiast obrazu

**Błąd:**
```
Gemini 2.0 API returned no image data: {"candidates" => [{"content" => {"parts" => [{"text" => "I can't generate images..."}]}}]}
```

**Przyczyna:** Użycie modelu tekstowego (`gemini-2.0-flash-exp`) zamiast modelu obrazowego.

**Rozwiązanie:**
```ruby
# ŹLE
"/v1beta/models/gemini-2.0-flash-exp:generateContent"

# DOBRZE
"/v1beta/models/gemini-2.5-flash-image:generateContent"
```

### 2. Brak responseModalities

**Błąd:**
```
Model does not support the requested response modalities: image
```

**Rozwiązanie:** Dodaj konfigurację:
```ruby
generationConfig: {
  responseModalities: ["IMAGE"]
}
```

### 3. Nieprawidłowy responseMimeType

**Błąd:**
```
allowed mimetypes are `text/plain`, `application/json`...
```

**Rozwiązanie:** NIE używaj `responseMimeType: "image/png"` - to pole jest tylko dla tekstu.

### 4. response.usage nie istnieje (Langchain)

**Błąd:**
```
undefined method 'usage' for Langchain::LLM::OpenAIResponse
```

**Rozwiązanie:**
```ruby
# ŹLE
response.usage["total_tokens"]
response.usage&.dig("prompt_tokens")

# DOBRZE
response.total_tokens
response.prompt_tokens
response.completion_tokens
```

### 5. Pusty background_prompt

**Błąd:** Obraz się nie generuje, creative ma status "failed".

**Przyczyna:** Tekst nie został wygenerowany przed próbą generowania obrazu.

**Rozwiązanie:** Zawsze generuj tekst PRZED obrazem i waliduj:
```ruby
raise "Missing prompt" if creative.background_prompt.blank?
```

### 6. Model 404 Not Found

**Błąd:**
```
models/gemini-2.0-flash-exp-image-generation is not found
```

**Rozwiązanie:** Sprawdź dostępne modele:
```ruby
conn.get('/v1beta/models')
```

Aktualne modele do obrazów (grudzień 2025):
- `gemini-2.5-flash-image`
- `gemini-2.5-flash-image-preview`
- `imagen-4.0-generate-001`

### 7. Enkodowanie polskich znaków

**Objaw:** W logach widać `kt��ra` zamiast `która`.

**Rozwiązanie:** To tylko problem z logowaniem, nie z danymi. Sprawdź `response.completion` - powinno być OK.

---

## Checklist przed implementacją

### Konfiguracja

- [ ] Klucz API OpenAI w credentials
- [ ] Klucz API Google (Gemini/Imagen) w credentials lub AppConfig
- [ ] Langchain skonfigurowany w initializer
- [ ] Gem `image_processing` i libvips zainstalowane

### Model obrazowy

- [ ] Użyty model z `-image` w nazwie (np. `gemini-2.5-flash-image`)
- [ ] Dodane `responseModalities: ["IMAGE"]` w request body
- [ ] NIE dodane `responseMimeType` dla obrazów
- [ ] Obsługa błędów gdy API nie zwraca obrazu

### Przepływ

- [ ] Tekst generowany PRZED obrazem
- [ ] Walidacja `background_prompt.present?` przed generowaniem obrazu
- [ ] Status creative aktualizowany na końcu (`generated` lub `failed`)
- [ ] Retry logic dla transient errors (429, 500, 503)

### Langchain API

- [ ] `response.completion` dla treści
- [ ] `response.total_tokens` dla tokenów (nie `response.usage`)
- [ ] `response_format: { type: "json_object" }` dla JSON output

---

## Konfiguracja modeli

### Tabela porównawcza

| Cecha | GPT-4o-mini | Gemini 2.5 Flash Image | Imagen 4 |
|-------|-------------|------------------------|----------|
| Typ | Tekst | Obraz | Obraz |
| Koszt | Niski | Niski | Wysoki |
| Szybkość | ~2-5s | ~5-15s | ~10-20s |
| Jakość | Dobra | Dobra | Bardzo dobra |
| Endpoint | chat/completions | generateContent | predict |

### Przykładowa konfiguracja w AppConfig

```ruby
# Schema
create_table :app_configs do |t|
  t.string :gemini_api_key  # zaszyfrowane
  t.string :ai_model, default: "gemini-2.5-flash-image"
end

# Użycie
model = AppConfig.first&.ai_model || "gemini-2.5-flash-image"

case model
when /^imagen/
  generate_with_imagen(api_key)
else
  generate_with_gemini(api_key)
end
```

---

## Podsumowanie

1. **Zawsze używaj odpowiedniego modelu** - modele tekstowe NIE generują obrazów
2. **Kolejność ma znaczenie** - tekst przed obrazem
3. **Waliduj dane wejściowe** - sprawdź czy prompt istnieje
4. **Sprawdź API konkretnej biblioteki** - Langchain ma inne metody niż surowe API
5. **Loguj błędy** - zapisuj pełne response body przy błędach
6. **Testuj ręcznie** - `rails runner` pozwala szybko debugować

---

*Dokument utworzony: 13 grudnia 2025*
*Ostatnia aktualizacja: 13 grudnia 2025*
