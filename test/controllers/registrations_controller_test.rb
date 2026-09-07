require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "creates a user and signs them in" do
    assert_difference "User.count", 1 do
      post registration_url, params: {
        user: { first_name: "Nora", last_name: "Vidal", email: "nora@example.com",
                password: "password123", password_confirmation: "password123", city: "Sevilla" }
      }
    end
    assert_redirected_to root_url
  end

  test "rejects mismatched password confirmation" do
    assert_no_difference "User.count" do
      post registration_url, params: {
        user: { first_name: "Nora", last_name: "Vidal", email: "nora@example.com",
                password: "password123", password_confirmation: "different" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "rejects a duplicate email" do
    assert_no_difference "User.count" do
      post registration_url, params: {
        user: { first_name: "Dup", last_name: "User", email: users(:marti).email,
                password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end
end
