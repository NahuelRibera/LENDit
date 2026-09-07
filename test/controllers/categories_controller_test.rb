require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "index lists active categories" do
    get categories_url
    assert_response :success
    assert_select ".category-tile", count: Category.active.count
  end

  test "show lists only published listings in that category" do
    get category_url(categories(:consoles).slug)
    assert_response :success
    assert_select ".listing-card", count: 1
  end

  test "show 404s for an unknown slug" do
    get category_url("does-not-exist")
    assert_response :not_found
  end
end
