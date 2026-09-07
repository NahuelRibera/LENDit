require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "between finds or creates a single conversation per listing + user pair, regardless of argument order" do
    a = Conversation.between(users(:marti), users(:nahuel), listing: listings(:vive))
    b = Conversation.between(users(:nahuel), users(:marti), listing: listings(:vive))
    assert_equal a, b
  end

  test "between creates separate conversations for different listings" do
    a = Conversation.between(users(:marti), users(:nahuel), listing: listings(:vive))
    b = Conversation.between(users(:marti), users(:nahuel), listing: listings(:draft_drone))
    assert_not_equal a, b
  end

  test "other_participant returns whichever user isn't the given one" do
    conversation = conversations(:vive_thread)
    assert_equal users(:elena), conversation.other_participant(users(:marti))
    assert_equal users(:marti), conversation.other_participant(users(:elena))
  end

  test "participant? is false for a third user" do
    assert_not conversations(:vive_thread).participant?(users(:nahuel))
  end

  test "unread_for? is true when there's a message after the user's last read" do
    conversation = conversations(:vive_thread)
    messages(:reply_message) # touch fixture reference

    assert conversation.unread_for?(users(:marti))
    conversation.mark_read_for!(users(:marti))
    assert_not conversation.unread_for?(users(:marti))
  end

  test "unread_for scope finds conversations with unread messages for a user" do
    conversation = conversations(:vive_thread)
    assert_includes Conversation.unread_for(users(:marti)), conversation

    conversation.mark_read_for!(users(:marti))
    assert_not_includes Conversation.unread_for(users(:marti)), conversation
  end
end
