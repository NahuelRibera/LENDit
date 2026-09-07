require "test_helper"

class ListingPolicyTest < ActiveSupport::TestCase
  test "anyone can view a published listing" do
    assert ListingPolicy.new(nil, listings(:vive)).show?
    assert ListingPolicy.new(users(:elena), listings(:vive)).show?
  end

  test "only the owner can preview a draft listing" do
    assert ListingPolicy.new(users(:marti), listings(:draft_drone)).show?
    assert_not ListingPolicy.new(users(:elena), listings(:draft_drone)).show?
    assert_not ListingPolicy.new(nil, listings(:draft_drone)).show?
  end

  test "any signed-in user can create a listing" do
    assert ListingPolicy.new(users(:marti), Listing.new).create?
    assert_not ListingPolicy.new(nil, Listing.new).create?
  end

  test "only the owner can update, manage status, or manage images" do
    listing = listings(:vive)
    assert ListingPolicy.new(users(:marti), listing).update?
    assert_not ListingPolicy.new(users(:elena), listing).update?
    assert ListingPolicy.new(users(:marti), listing).manage_status?
    assert ListingPolicy.new(users(:marti), listing).manage_images?
  end
end
