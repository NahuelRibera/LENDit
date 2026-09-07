require "test_helper"

class ConversationPolicyTest < ActiveSupport::TestCase
  test "only participants can view or message in a conversation" do
    conversation = conversations(:vive_thread)
    assert ConversationPolicy.new(users(:marti), conversation).show?
    assert ConversationPolicy.new(users(:elena), conversation).show?
    assert_not ConversationPolicy.new(users(:nahuel), conversation).show?
    assert_not ConversationPolicy.new(nil, conversation).show?
  end

  test "scope resolves only conversations the user participates in" do
    resolved = ConversationPolicy::Scope.new(users(:marti), Conversation.all).resolve
    assert_includes resolved, conversations(:vive_thread)

    resolved_for_third_party = ConversationPolicy::Scope.new(users(:nahuel), Conversation.all).resolve
    assert_not_includes resolved_for_third_party, conversations(:vive_thread)
  end
end
