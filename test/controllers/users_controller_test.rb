require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "anyone can view a public profile, without exposing the email" do
    get user_url(users(:marti))
    assert_response :success
    assert_select ".profile-header__name", text: users(:marti).full_name
    assert_no_match users(:marti).email, response.body
  end

  test "shows the user's published listings" do
    get user_url(users(:marti))
    assert_response :success
    assert_select "a.listing-card", count: users(:marti).listings.published.count
    assert_match listings(:vive).title, response.body
  end

  test "even the owner sees their own listings on their own public profile" do
    sign_in_as users(:marti)
    get user_url(users(:marti))
    assert_response :success
    assert_match listings(:vive).title, response.body
  end
end
