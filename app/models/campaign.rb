class Campaign < ApplicationRecord
  # Enums
  enum :status, { draft: 0, processing: 1, completed: 2, failed: 3 }, default: :draft

  # Associations
  belongs_to :brand
  has_many :creatives, dependent: :destroy

  # Delegations
  delegate :primary_color, to: :brand, prefix: true

  # Validations
  validates :product_name, presence: true, length: { maximum: 100 }
  validates :target_audience, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Broadcasts for Turbo Streams
  broadcasts  # Broadcasts to the campaign stream itself
end
