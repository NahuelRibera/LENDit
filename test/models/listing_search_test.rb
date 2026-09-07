require "test_helper"

class ListingSearchTest < ActiveSupport::TestCase
  test "only returns published listings" do
    results = ListingSearch.new({}).results
    assert_includes results, listings(:vive)
    assert_not_includes results, listings(:draft_drone)
    assert_not_includes results, listings(:paused_bike)
  end

  test "full-text search matches on title" do
    results = ListingSearch.new({ q: "Vive" }).results
    assert_equal [listings(:vive)], results.to_a
  end

  test "falls back to fuzzy trigram matching for a near-miss query" do
    results = ListingSearch.new({ q: "Gitar" }).results
    assert_includes results, listings(:guitar)
  end

  test "filters by category" do
    results = ListingSearch.new({ category_id: categories(:sports).id }).results
    assert_equal [listings(:tent)], results.to_a
  end

  test "filters by condition" do
    results = ListingSearch.new({ condition: "fair" }).results
    assert_equal [listings(:guitar)], results.to_a
  end

  test "filters by city, case-insensitively" do
    results = ListingSearch.new({ city: "madrid" }).results
    assert_equal [listings(:canon), listings(:tent)].sort_by(&:id), results.to_a.sort_by(&:id)
  end

  test "filters by price range" do
    results = ListingSearch.new({ price_min: "20", price_max: "30" }).results
    assert_equal [listings(:vive)], results.to_a
  end

  test "filters by minimum owner rating" do
    # both canon and tent belong to elena (rating 4.8); marti (4.5) and
    # nahuel (0.0) fall below the 4.6 threshold
    results = ListingSearch.new({ min_owner_rating: "4.6" }).results
    assert_equal [listings(:canon), listings(:tent)].sort_by(&:id), results.to_a.sort_by(&:id)
  end

  test "sorts by price ascending and descending" do
    asc = ListingSearch.new({ sort: "price_asc" }).results.to_a
    assert_equal asc, asc.sort_by(&:price_cents)

    desc = ListingSearch.new({ sort: "price_desc" }).results.to_a
    assert_equal desc, desc.sort_by(&:price_cents).reverse
  end

  test "defaults to newest first when there is no query" do
    results = ListingSearch.new({}).results.to_a
    expected = Listing.published.order(created_at: :desc, id: :desc).to_a
    assert_equal expected, results
  end
end
