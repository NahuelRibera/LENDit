require "test_helper"

module Account
  class BorrowsControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get account_borrows_url
      assert_redirected_to new_session_url
    end

    test "shows only rentals where the current user is the borrower, filtered by status" do
      sign_in_as users(:elena) # borrower on pending_request

      get account_borrows_url(status: "pending")
      assert_response :success
      assert_select ".rental-row", count: 1
    end
  end
end
