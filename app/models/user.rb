class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :campaigns, through: :brands
  has_many :creatives, through: :campaigns

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
