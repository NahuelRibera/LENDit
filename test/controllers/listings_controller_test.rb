require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  test "guests can view a published listing but not create one" do
    get listing_url(listings(:vive))
    assert_response :success

    get new_listing_url
    assert_redirected_to new_session_url
  end

  test "guests cannot view someone else's draft listing" do
    get listing_url(listings(:draft_drone))
    assert_redirected_to root_url
  end

  test "the owner can preview their own draft listing" do
    sign_in_as users(:marti)
    get listing_url(listings(:draft_drone))
    assert_response :success
  end

  test "an authenticated user can create a draft listing" do
    sign_in_as users(:marti)

    assert_difference "Listing.count", 1 do
      post listings_url, params: {
        listing: { title: "Nikon D7500", description: "Great condition DSLR with kit lens.",
                   category_id: categories(:cameras).id, condition: "good", price: "35", city: "Barcelona" }
      }
    end

    listing = Listing.order(:created_at).last
    assert listing.draft?
    assert_redirected_to edit_listing_path(listing)
  end

  test "a user cannot edit someone else's listing" do
    sign_in_as users(:elena)
    get edit_listing_url(listings(:vive))
    assert_redirected_to root_url
  end

  test "the owner can update their own listing" do
    sign_in_as users(:marti)
    patch listing_url(listings(:vive)), params: { listing: { title: "HTC Vive 2 (like new)" } }
    assert_redirected_to edit_listing_path(listings(:vive))
    assert_equal "HTC Vive 2 (like new)", listings(:vive).reload.title
  end
end
