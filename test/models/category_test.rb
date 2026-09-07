require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "generates a slug from the name when blank" do
    category = Category.create!(name: "Outdoor Gear", icon_key: "activity")
    assert_equal "outdoor-gear", category.slug
  end

  test "requires a unique name and slug" do
    duplicate = Category.new(name: categories(:cameras).name, icon_key: "camera")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "ordered scope sorts by position then name" do
    assert_equal categories(:cameras), Category.active.ordered.first
  end
end
