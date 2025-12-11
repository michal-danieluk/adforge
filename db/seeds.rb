# Seed data dla AdForge

# Użytkownik
user = User.find_or_create_by!(email_address: 'test@example.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
end
puts "✓ Użytkownik: test@example.com / password"

# Brand 1: EcoBottle
brand1 = Brand.create!(
  user: user,
  name: 'EcoBottle',
  tone_of_voice: 'friendly',
  brand_colors_attributes: [
    { hex_value: '#2ECC71', primary: true },
    { hex_value: '#27AE60', primary: false },
    { hex_value: '#ECF0F1', primary: false }
  ]
)
puts "✓ Brand: #{brand1.name} (#{brand1.brand_colors.count} kolory)"

brand1.campaigns.create!(
  product_name: 'EcoBottle Pro',
  target_audience: 'Ekologiczni millenialsi 25-35 lat',
  description: 'Stylowa butelka ze stali nierdzewnej, idealna na siłownię i wycieczki'
)
puts "  ✓ Kampania: EcoBottle Pro"

# Brand 2: TechFlow
brand2 = Brand.create!(
  user: user,
  name: 'TechFlow',
  tone_of_voice: 'professional',
  brand_colors_attributes: [
    { hex_value: '#3498DB', primary: true },
    { hex_value: '#2C3E50', primary: false },
    { hex_value: '#ECF0F1', primary: false }
  ]
)
puts "✓ Brand: #{brand2.name} (#{brand2.brand_colors.count} kolory)"

brand2.campaigns.create!(
  product_name: 'TechFlow CRM',
  target_audience: 'Właściciele małych firm i managerowie',
  description: 'Intuicyjny system CRM dla małych zespołów, zwiększ sprzedaż o 30%'
)
puts "  ✓ Kampania: TechFlow CRM"

# Brand 3: FitLife
brand3 = Brand.create!(
  user: user,
  name: 'FitLife',
  tone_of_voice: 'casual',
  brand_colors_attributes: [
    { hex_value: '#E74C3C', primary: true },
    { hex_value: '#C0392B', primary: false },
    { hex_value: '#F39C12', primary: false }
  ]
)
puts "✓ Brand: #{brand3.name} (#{brand3.brand_colors.count} kolory)"

brand3.campaigns.create!(
  product_name: 'FitLife Premium Membership',
  target_audience: 'Aktywni ludzie 20-45 lat chcący się rozwijać',
  description: 'Roczne członkostwo premium - nielimitowane treningi, konsultacje z trenerem, plany żywieniowe'
)
puts "  ✓ Kampania: FitLife Premium"

puts ""
puts "=" * 50
puts "Gotowe! Dane testowe utworzone:"
puts "- Użytkownik: test@example.com / password"
puts "- Brandy: #{Brand.count}"
puts "- Kampanie: #{Campaign.count}"
puts "=" * 50
