require "test_helper"

class RentalsControllerTest < ActionDispatch::IntegrationTest
  test "a signed-in user can request to book a published listing" do
    sign_in_as users(:marti) # elena owns the tent listing, marti does not

    assert_difference "Rental.count", 1 do
      post listing_rentals_url(listings(:tent)), params: {
        rental: { start_date: 40.days.from_now.to_date, end_date: 42.days.from_now.to_date }
      }
    end

    rental = Rental.order(:created_at).last
    assert_redirected_to rental_path(rental)
    assert_equal users(:elena), rental.lender # tent's owner
  end

  # Regression test: requested_at is NOT NULL in the schema and must be
  # set server-side by the model, never trusted from request params — a
  # missing before_validation here previously crashed this exact request
  # with ActiveRecord::NotNullViolation.
  test "requested_at is populated automatically and cannot be spoofed from params" do
    sign_in_as users(:marti)
    spoofed = 10.years.ago

    post listing_rentals_url(listings(:tent)), params: {
      rental: { start_date: 40.days.from_now.to_date, end_date: 42.days.from_now.to_date, requested_at: spoofed }
    }

    rental = Rental.order(:created_at).last
    assert_not_nil rental.requested_at
    assert_in_delta Time.current, rental.requested_at, 5.seconds
  end

  test "cannot book your own listing" do
    sign_in_as users(:elena) # elena owns the tent listing
    post listing_rentals_url(listings(:tent)), params: {
      rental: { start_date: 40.days.from_now.to_date, end_date: 42.days.from_now.to_date }
    }
    assert_redirected_to listing_path(listings(:tent))
  end

  test "invalid dates redirect back to the listing with a clear error" do
    sign_in_as users(:marti)
    post listing_rentals_url(listings(:tent)), params: {
      rental: { start_date: 2.days.ago.to_date, end_date: 1.day.from_now.to_date }
    }
    assert_redirected_to listing_path(listings(:tent))
    follow_redirect!
    assert_match(/can't be in the past/, flash[:alert])
  end

  test "only a participant can view a rental" do
    sign_in_as users(:nahuel)
    get rental_url(rentals(:pending_request))
    assert_redirected_to root_url
  end

  test "a participant can view a rental" do
    sign_in_as rentals(:pending_request).borrower
    get rental_url(rentals(:pending_request))
    assert_response :success
  end
end
