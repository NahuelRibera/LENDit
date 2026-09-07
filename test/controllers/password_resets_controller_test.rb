require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "requesting a reset for a known email enqueues a mail" do
    assert_enqueued_email_with PasswordMailer, :reset, args: [users(:marti)] do
      post password_reset_url, params: { email: users(:marti).email }
    end
    assert_redirected_to new_session_url
  end

  test "requesting a reset for an unknown email responds the same way" do
    assert_no_enqueued_emails do
      post password_reset_url, params: { email: "nobody@example.com" }
    end
    assert_redirected_to new_session_url
  end

  test "a valid token allows setting a new password" do
    user = users(:marti)
    token = user.generate_token_for(:password_reset)

    patch password_reset_url(token: token), params: {
      user: { password: "newpassword123", password_confirmation: "newpassword123" }
    }

    assert_redirected_to new_session_url
    assert user.reload.authenticate("newpassword123")
  end

  test "an invalid token is rejected" do
    patch password_reset_url(token: "not-a-real-token"), params: {
      user: { password: "newpassword123", password_confirmation: "newpassword123" }
    }
    assert_redirected_to new_password_reset_url
  end
end
