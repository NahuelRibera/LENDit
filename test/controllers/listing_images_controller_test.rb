require "test_helper"

class ListingImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @png = Rails.root.join("app/assets/images/logo.png")
  end

  test "uploading photos attaches them and makes the first one primary" do
    sign_in_as users(:marti)
    listing = listings(:draft_drone)

    assert_difference "listing.listing_images.count", 2 do
      post listing_images_url(listing), params: {
        listing_image: { files: [fixture_upload, fixture_upload] }
      }
    end

    assert listing.listing_images.ordered.first.is_primary?
  end

  test "a non-owner cannot upload photos to someone else's listing" do
    sign_in_as users(:elena)
    post listing_images_url(listings(:draft_drone)), params: { listing_image: { files: [fixture_upload] } }
    assert_redirected_to root_url
  end

  test "make_primary reassigns the single primary image" do
    sign_in_as users(:marti)
    listing = listings(:vive)
    first = create_image!(listing, is_primary: true, position: 0)
    second = create_image!(listing, is_primary: false, position: 1)

    patch listing_image_url(listing, second), params: { make_primary: "1" }

    assert_not first.reload.is_primary?
    assert second.reload.is_primary?
  end

  test "destroying the primary image promotes the next one" do
    sign_in_as users(:marti)
    listing = listings(:vive)
    first = create_image!(listing, is_primary: true, position: 0)
    second = create_image!(listing, is_primary: false, position: 1)

    delete listing_image_url(listing, first)

    assert second.reload.is_primary?
  end

  private

  def fixture_upload
    Rack::Test::UploadedFile.new(@png.to_s, "image/png")
  end

  def create_image!(listing, is_primary:, position:)
    image = listing.listing_images.build(is_primary: is_primary, position: position)
    image.file.attach(io: File.open(@png), filename: "logo.png", content_type: "image/png")
    image.save!
    image
  end
end
