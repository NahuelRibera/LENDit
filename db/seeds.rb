# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

CATEGORIES = [
  { name: "Cameras", icon_key: "camera", position: 1 },
  { name: "Fashion", icon_key: "tag", position: 2 },
  { name: "Sports", icon_key: "activity", position: 3 },
  { name: "Audio", icon_key: "headphones", position: 4 },
  { name: "Consoles", icon_key: "tv", position: 5 },
  { name: "Furniture", icon_key: "home", position: 6 },
  { name: "Tools", icon_key: "tool", position: 7 },
  { name: "Music", icon_key: "music", position: 8 },
].freeze

CATEGORIES.each do |attrs|
  Category.find_or_create_by!(name: attrs[:name]) do |category|
    category.icon_key = attrs[:icon_key]
    category.position = attrs[:position]
  end
end

puts "Seeded #{Category.count} categories."
