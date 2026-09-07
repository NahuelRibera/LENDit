require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "shows only the current user's notifications" do
    sign_in_as users(:marti)
    Notification.create!(recipient: users(:marti), notifiable: rentals(:pending_request), verb: "rental_requested")
    Notification.create!(recipient: users(:elena), notifiable: rentals(:pending_request), verb: "rental_requested")

    get notifications_url
    assert_response :success
    assert_select ".notification-row", count: 1
  end

  test "marking one read updates it and redirects to its target" do
    sign_in_as users(:marti)
    notification = Notification.create!(recipient: users(:marti), notifiable: rentals(:pending_request), verb: "rental_requested")

    post notification_read_url(notification)

    assert notification.reload.read?
    assert_redirected_to rental_path(rentals(:pending_request))
  end

  test "mark all as read clears every unread notification" do
    sign_in_as users(:marti)
    Notification.create!(recipient: users(:marti), notifiable: rentals(:pending_request), verb: "rental_requested")
    Notification.create!(recipient: users(:marti), notifiable: rentals(:accepted_booking), verb: "rental_accepted")

    post notifications_read_all_url

    assert_equal 0, users(:marti).notifications.unread.count
  end
end
