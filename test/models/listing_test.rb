require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "valid listing from fixture" do
    assert listings(:vive).valid?
  end

  test "price is a virtual accessor over price_cents" do
    listing = listings(:vive)
    assert_equal 22.0, listing.price
    listing.price = "30.50"
    assert_equal 3050, listing.price_cents
  end

  test "requires a positive price" do
    listing = listings(:vive)
    listing.price = "0"
    assert_not listing.valid?
    assert_includes listing.errors[:price], "must be greater than 0"
  end

  test "requires a valid condition" do
    listing = listings(:vive)
    listing.condition = "brand_new"
    assert_not listing.valid?
  end

  test "publish moves a draft to published" do
    listing = listings(:draft_drone)
    listing.publish!
    assert listing.published?
  end

  test "cannot publish an already-published listing" do
    listing = listings(:vive)
    assert_raises(Listing::InvalidTransitionError) { listing.publish! }
  end

  test "pause moves a published listing to paused, and reactivate moves it back" do
    listing = listings(:vive)
    listing.pause!
    assert listing.paused?
    listing.reactivate!
    assert listing.published?
  end

  test "archive is allowed from draft, published, or paused, but not twice" do
    listing = listings(:vive)
    listing.archive!
    assert listing.archived?
    assert_raises(Listing::InvalidTransitionError) { listing.archive! }
  end

  test "restricts destroying a user or category that still has listings" do
    assert_no_difference "User.count" do
      assert_not users(:marti).destroy
    end
    assert_no_difference "Category.count" do
      assert_not categories(:consoles).destroy
    end
  end
end
