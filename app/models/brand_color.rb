class BrandColor < ApplicationRecord
  belongs_to :brand

  # Validations
  validates :hex_value, presence: true,
                        format: { with: /\A#[0-9A-F]{6}\z/i, message: "must be a valid hex color (e.g., #FF5733)" },
                        uniqueness: { scope: :brand_id, message: "already exists in this brand" }

  # Set default for primary flag
  after_initialize :set_default_primary, if: :new_record?

  private

  def set_default_primary
    self.primary ||= false
  end
end
