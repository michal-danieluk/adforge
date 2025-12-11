class AppConfig < ApplicationRecord
  encrypts :gemini_api_key

  validate :singleton_record, on: :create

  def self.current
    first || new
  end

  private

  def singleton_record
    if AppConfig.exists?
      errors.add(:base, "Only one AppConfig record allowed")
    end
  end
end