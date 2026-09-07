require "test_helper"

class RentalPolicyTest < ActiveSupport::TestCase
  test "only a participant can view a rental" do
    rental = rentals(:pending_request)
    assert RentalPolicy.new(rental.borrower, rental).show?
    assert RentalPolicy.new(rental.lender, rental).show?
    assert_not RentalPolicy.new(users(:nahuel), rental).show?
  end

  test "only the lender can accept or decline" do
    rental = rentals(:pending_request)
    assert RentalPolicy.new(rental.lender, rental).accept?
    assert_not RentalPolicy.new(rental.borrower, rental).accept?
    assert RentalPolicy.new(rental.lender, rental).decline?
    assert_not RentalPolicy.new(rental.borrower, rental).decline?
  end

  test "either participant can attempt to cancel (model enforces the finer rule)" do
    rental = rentals(:pending_request)
    assert RentalPolicy.new(rental.borrower, rental).cancel?
    assert RentalPolicy.new(rental.lender, rental).cancel?
    assert_not RentalPolicy.new(users(:nahuel), rental).cancel?
  end

  test "scope resolves only rentals the user participates in" do
    resolved = RentalPolicy::Scope.new(users(:marti), Rental.all).resolve
    assert_includes resolved, rentals(:pending_request) # marti is lender
    assert_includes resolved, rentals(:accepted_booking) # marti is borrower
    assert_not_includes resolved, rentals(:completed_rental)
  end
end
