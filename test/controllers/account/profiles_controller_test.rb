require "test_helper"

module Account
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get edit_account_profile_url
      assert_redirected_to new_session_url
    end

    test "an authenticated user can update their own profile" do
      sign_in_as users(:marti)

      patch account_profile_url, params: { user: { bio: "Updated bio", city: "Girona" } }

      assert_redirected_to edit_account_profile_url
      assert_equal "Updated bio", users(:marti).reload.bio
    end

    test "cannot update with an invalid attribute" do
      sign_in_as users(:marti)

      patch account_profile_url, params: { user: { first_name: "" } }

      assert_response :unprocessable_entity
    end
  end
end
