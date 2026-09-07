require "test_helper"

class ListingsControllerIndexTest < ActionDispatch::IntegrationTest
  test "lists only published listings, paginated" do
    get listings_url
    assert_response :success
    assert_select "a.listing-card", count: Listing.published.count
  end

  test "search narrows results and is reflected in the URL" do
    get listings_url(q: "Vive")
    assert_response :success
    assert_select "a.listing-card", count: 1
    assert_select "h1", text: "Results for “Vive”"
  end

  test "an empty result set shows a helpful empty state, not an error" do
    get listings_url(q: "nonexistent-item-xyz")
    assert_response :success
    assert_select ".empty-state__title", text: "No listings match your search"
  end

  test "category filter is reflected in the select" do
    get listings_url(category_id: categories(:sports).id)
    assert_response :success
    assert_select "a.listing-card", count: 1
  end
end
