class Creative < ApplicationRecord
  belongs_to :campaign
  has_one_attached :raw_background    # Will be AI-generated later
  has_one_attached :final_image       # Composed image (bg + brand overlay)

  # Validations
  validates :status, inclusion: { in: %w[pending generating generated failed] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: "generated") }
  scope :pending_generation, -> { where(status: %w[pending generating]) }

  # State methods
  def pending?
    status == "pending"
  end

  def generating?
    status == "generating"
  end

  def generated?
    status == "generated"
  end

  def failed?
    status == "failed"
  end
end
