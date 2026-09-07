require "test_helper"

class HomeControllerRecentlyViewedTest < ActionDispatch::IntegrationTest
  test "a signed-in user's viewed listing is persisted and shown on the homepage" do
    sign_in_as users(:elena)
    get listing_url(listings(:vive))

    assert_equal 1, users(:elena).recently_viewed_listings.count

    get root_url
    assert_select "a.listing-card[href=?]", listing_path(listings(:vive))
  end

  test "a guest's viewed listing is tracked in the session, not the database" do
    get listing_url(listings(:vive))
    assert_equal 0, RecentlyViewedListing.count

    get root_url
    assert_select "a.listing-card[href=?]", listing_path(listings(:vive))
  end

  test "viewing a listing twice does not duplicate the recently-viewed record" do
    sign_in_as users(:elena)
    get listing_url(listings(:vive))
    get listing_url(listings(:vive))

    assert_equal 1, users(:elena).recently_viewed_listings.count
  end
end
