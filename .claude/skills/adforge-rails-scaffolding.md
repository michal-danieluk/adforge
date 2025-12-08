# Skill: Rails Scaffolding for AdForge

## When to Use
When creating CRUD operations for core models: `Brand`, `Campaign`, `Creative`.

## Philosophy
Scaffolds are GOOD in MVP. They generate 80% of what you need. Customize the remaining 20%.

## Standard Workflow

### 1. Generate Scaffold
```bash
rails g scaffold ModelName attribute:type another:type
rails db:migrate
git add .
git commit -m "Generate ModelName scaffold"
```

### 2. Customize Model
Add to `app/models/model_name.rb`:
- Associations (`has_many`, `belongs_to`).
- Validations (`presence`, `format`, `inclusion`).
- File attachments (`has_one_attached :logo`).
- Custom methods (e.g., `def primary_color`).

**Git commit:** `"Add ModelName associations and validations"`

### 3. Update Controller (Strong Params)
In `app/controllers/model_names_controller.rb`, update `model_name_params`:
```ruby
def model_name_params
  params.require(:model_name).permit(
    :name, 
    :other_field,
    nested_models_attributes: [:id, :field, :_destroy]
  )
end
```

**Git commit:** `"Whitelist nested attributes in ModelName controller"`

### 4. Style Views with Tailwind
- Use utility classes: `border`, `rounded`, `px-3`, `py-2`, `bg-blue-600`, etc.
- NO custom CSS files.
- NO inline styles.

**Git commit:** `"Style ModelName views with Tailwind"`

### 5. Write System Test
File: `test/system/model_names_test.rb`

Test the happy path:
1. User visits `/model_names/new`.
2. Fills form with valid data.
3. Clicks submit.
4. Sees success message.
5. Sees data displayed correctly.

**Git commit:** `"Add system test for ModelName CRUD"`

## Example: Brand with Nested BrandColors
```bash
rails g scaffold Brand name:string tone_of_voice:string
rails g model BrandColor brand:references hex_value:string primary:boolean
rails db:migrate
```

**Model changes:**
```ruby
# app/models/brand.rb
has_many :brand_colors, dependent: :destroy
accepts_nested_attributes_for :brand_colors, allow_destroy: true

# app/models/brand_color.rb
belongs_to :brand
validates :hex_value, format: { with: /\A#[0-9A-F]{6}\z/i }
```

**Controller strong params:**
```ruby
def brand_params
  params.require(:brand).permit(
    :name, 
    :tone_of_voice,
    brand_colors_attributes: [:id, :hex_value, :primary, :_destroy]
  )
end
```

## Common Pitfalls

### Pitfall 1: Forgetting `dependent: :destroy`
**Problem:** Deleting parent leaves orphaned children.
**Fix:** Always add `dependent: :destroy` to `has_many`.

### Pitfall 2: Not Whitelisting Nested Attributes
**Problem:** Nested form submits but data doesn't save.
**Fix:** Add `nested_models_attributes: [...]` to strong params.

### Pitfall 3: N+1 Queries in Index View
**Problem:** `@brands.each { |b| b.brand_colors }` triggers query per brand.
**Fix:** In controller: `@brands = Brand.includes(:brand_colors).all`

## Checklist Before Committing
- [ ] Model has validations for all required fields.
- [ ] Controller strong params whitelist all form fields.
- [ ] Views use Tailwind (no custom CSS).
- [ ] System test covers create/update/delete.
- [ ] No N+1 queries (check with `rails db:query_log`).

---

**Use this skill for every new model in AdForge.**
