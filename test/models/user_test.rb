require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user from fixture" do
    assert users(:marti).valid?
  end

  test "requires a unique, well-formed email" do
    user = User.new(first_name: "A", last_name: "B", email: "not-an-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"

    user.email = users(:marti).email.upcase
    user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "normalizes email to lowercase, stripped" do
    user = User.new(first_name: "A", last_name: "B", email: "  Test@Example.com  ", password: "password123")
    user.valid?
    assert_equal "test@example.com", user.email
  end

  test "enforces a minimum password length" do
    user = User.new(first_name: "A", last_name: "B", email: "new@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "authenticates with the correct password only" do
    user = users(:marti)
    assert user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end

  test "password reset token round-trips and expires" do
    user = users(:marti)
    token = user.generate_token_for(:password_reset)
    assert_equal user, User.find_by_token_for(:password_reset, token)
  end

  test "password reset token is invalidated by a password change" do
    user = users(:marti)
    token = user.generate_token_for(:password_reset)
    user.update!(password: "brandnewpassword")
    assert_nil User.find_by_token_for(:password_reset, token)
  end
end
