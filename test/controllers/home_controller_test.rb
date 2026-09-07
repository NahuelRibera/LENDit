require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the homepage with the LENDit brand and marketplace navigation" do
    get root_url

    assert_response :success
    assert_select "img.navbar__logo[alt=?]", "LENDit"
    assert_select "input[name=q]"
    assert_select ".category-tile", count: Category.active.count
    assert_select ".home-intro__eyebrow", false
    assert_select "h2", text: "Explore by category"
    assert_select "h2", text: "Recently added"
    assert_select "h2", text: "Recently viewed"
    assert_select "a.listing-card", count: Listing.published.count
    assert_select ".empty-state__title", text: "You haven't viewed anything yet"
  end

  test "a signed-in user never sees their own listing in Recently added" do
    sign_in_as users(:marti) # owns the vive listing
    get root_url

    assert_response :success
    assert_select "a.listing-card", count: Listing.published.count - 1
    assert_no_match listings(:vive).title, response.body
  end
end
