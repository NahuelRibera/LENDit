require "test_helper"

module Listings
  class StatusesControllerTest < ActionDispatch::IntegrationTest
    test "the owner can publish a draft listing" do
      sign_in_as users(:marti)
      patch listing_status_url(listings(:draft_drone)), params: { transition: "publish" }
      assert_redirected_to edit_listing_path(listings(:draft_drone))
      assert listings(:draft_drone).reload.published?
    end

    test "an invalid transition redirects back with an alert instead of raising" do
      sign_in_as users(:marti)
      patch listing_status_url(listings(:vive)), params: { transition: "publish" }
      assert_redirected_to edit_listing_path(listings(:vive))
      assert_equal "published", listings(:vive).reload.status
      assert_match(/Cannot move/, flash[:alert])
    end

    test "a non-owner cannot change a listing's status" do
      sign_in_as users(:elena)
      patch listing_status_url(listings(:vive)), params: { transition: "pause" }
      assert_redirected_to root_url
      assert listings(:vive).reload.published?
    end
  end
end
