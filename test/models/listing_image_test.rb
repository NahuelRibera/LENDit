require "test_helper"

class ListingImageTest < ActiveSupport::TestCase
  test "rejects a disallowed content type" do
    image = listings(:vive).listing_images.build
    image.file.attach(
      io: StringIO.new("not a real image"),
      filename: "note.txt",
      content_type: "text/plain"
    )
    assert_not image.valid?
    assert_includes image.errors[:file], "must be a PNG, JPEG, or WEBP image"
  end

  test "only one image per listing can be primary at the database level" do
    listing = listings(:vive)
    png = Rails.root.join("app/assets/images/logo.png")

    first = listing.listing_images.build(is_primary: true)
    first.file.attach(io: File.open(png), filename: "logo.png", content_type: "image/png")
    first.save!

    second = listing.listing_images.build(is_primary: true)
    second.file.attach(io: File.open(png), filename: "logo.png", content_type: "image/png")

    assert_raises(ActiveRecord::RecordNotUnique) { second.save!(validate: false) }
  end
end
