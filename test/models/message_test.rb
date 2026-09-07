require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "valid messages from fixtures" do
    assert messages(:first_message).valid?
  end

  test "a non-participant cannot be the sender" do
    message = conversations(:vive_thread).messages.new(sender: users(:nahuel), body: "hi")
    assert_not message.valid?
    assert_includes message.errors[:sender], "must be a participant in the conversation"
  end

  test "notifies the other participant on create" do
    assert_difference "Notification.count", 1 do
      conversations(:vive_thread).messages.create!(sender: users(:marti), body: "One more question")
    end

    notification = Notification.last
    assert_equal users(:elena), notification.recipient
    assert_equal users(:marti), notification.actor
    assert_equal "new_message", notification.verb
  end
end
