require "test_helper"

module Notifications
  class NotifierTest < ActiveSupport::TestCase
    test "creates a notification for the recipient" do
      rental = rentals(:pending_request)

      assert_difference "Notification.count", 1 do
        Notifier.notify(recipient: rental.lender, actor: rental.borrower, notifiable: rental, verb: "rental_requested")
      end
    end

    test "never notifies a user about their own action" do
      rental = rentals(:pending_request)

      assert_no_difference "Notification.count" do
        Notifier.notify(recipient: rental.borrower, actor: rental.borrower, notifiable: rental, verb: "rental_requested")
      end
    end

    test "does nothing when there is no recipient" do
      assert_no_difference "Notification.count" do
        Notifier.notify(recipient: nil, actor: users(:marti), notifiable: rentals(:pending_request), verb: "rental_requested")
      end
    end
  end
end
