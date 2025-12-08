class Brand < ApplicationRecord
  # Associations
  has_one_attached :logo
  has_many :brand_colors, dependent: :destroy
  accepts_nested_attributes_for :brand_colors, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :tone_of_voice, presence: true, inclusion: { in: %w[professional casual friendly authoritative] }

  # Logo validations
  validates :logo, content_type: { in: %w[image/png image/jpeg image/svg+xml], message: "must be a PNG, JPEG, or SVG" },
                   size: { less_than: 5.megabytes, message: "must be less than 5MB" },
                   if: :logo_attached?

  # Custom validations
  validate :must_have_at_least_one_color
  validate :must_have_exactly_one_primary_color

  # Helper method to get primary color
  def primary_color
    brand_colors.find_by(primary: true)&.hex_value || "#000000"
  end

  private

  def logo_attached?
    logo.attached?
  end

  def must_have_at_least_one_color
    if brand_colors.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "must have at least one brand color")
    end
  end

  def must_have_exactly_one_primary_color
    primary_count = brand_colors.reject(&:marked_for_destruction?).count(&:primary)
    if primary_count == 0
      errors.add(:base, "must have exactly one primary color")
    elsif primary_count > 1
      errors.add(:base, "can only have one primary color")
    end
  end
end
