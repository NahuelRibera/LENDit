require "test_helper"

class ListingAvailableToTest < ActiveSupport::TestCase
  test "excludes the given user's own listings" do
    results = Listing.published.available_to(users(:marti))
    assert_not_includes results, listings(:vive) # marti's own listing
    assert_includes results, listings(:canon) # elena's listing
  end

  test "shows everything to a guest (nil user)" do
    results = Listing.published.available_to(nil)
    assert_includes results, listings(:vive)
    assert_includes results, listings(:canon)
  end
end
