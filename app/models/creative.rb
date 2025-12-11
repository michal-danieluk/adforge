class Creative < ApplicationRecord
  # Enums
  enum :status, { pending: 0, generated: 1, failed: 2 }, default: :pending

  # Associations
  belongs_to :campaign
  has_one_attached :raw_background    # Will be AI-generated in Phase B
  has_one_attached :final_image       # Composed image (bg + brand overlay)

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Cost calculation (from ai_metadata or legacy columns)
  def ai_cost_dollars
    if ai_metadata && ai_metadata["cost_cents"]
      ai_metadata["cost_cents"] / 100.0
    elsif ai_cost_cents
      ai_cost_cents / 100.0
    else
      0
    end
  end

  # Class method to calculate total AI spend
  def self.total_ai_cost_cents
    sum(:ai_cost_cents) || 0
  end

  def self.total_ai_cost_dollars
    total_ai_cost_cents / 100.0
  end

  # Broadcasts for Turbo Streams
  broadcasts_to :campaign
end
