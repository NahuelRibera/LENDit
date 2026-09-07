require "test_helper"

module Account
  class ListingsControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get account_listings_url
      assert_redirected_to new_session_url
    end

    test "only shows the current user's own listings, including drafts" do
      sign_in_as users(:marti)
      get account_listings_url
      assert_response :success
      assert_select ".owner-listing-row", count: users(:marti).listings.count
    end
  end
end
