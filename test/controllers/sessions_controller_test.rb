require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "signs in with correct credentials" do
    post session_url, params: { email: users(:marti).email, password: "password123" }
    assert_redirected_to root_url
    follow_redirect!
    assert_select ".navbar__user-menu"
  end

  test "rejects incorrect password" do
    post session_url, params: { email: users(:marti).email, password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "signs out" do
    post session_url, params: { email: users(:marti).email, password: "password123" }
    delete session_url
    assert_redirected_to root_url
    follow_redirect!
    assert_select ".navbar__user-menu", false
  end
end
