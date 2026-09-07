require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  test "a participant can view the conversation" do
    sign_in_as users(:marti)
    get conversation_url(conversations(:vive_thread))
    assert_response :success
    assert_select ".message-bubble", count: 2
  end

  test "a non-participant cannot view someone else's conversation by guessing the id" do
    sign_in_as users(:nahuel)
    get conversation_url(conversations(:vive_thread))
    assert_redirected_to root_url
  end

  test "viewing a conversation marks it read" do
    sign_in_as users(:marti)
    assert conversations(:vive_thread).unread_for?(users(:marti))
    get conversation_url(conversations(:vive_thread))
    assert_not conversations(:vive_thread).reload.unread_for?(users(:marti))
  end
end
