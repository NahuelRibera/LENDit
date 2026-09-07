require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "a participant can send a message" do
    sign_in_as users(:marti)

    assert_difference "Message.count", 1 do
      post conversation_messages_url(conversations(:vive_thread)), params: { message: { body: "Sounds good!" } }
    end

    assert_redirected_to conversation_path(conversations(:vive_thread))
  end

  test "a non-participant cannot post into someone else's conversation" do
    sign_in_as users(:nahuel)
    post conversation_messages_url(conversations(:vive_thread)), params: { message: { body: "Sneaky" } }
    assert_redirected_to root_url
  end

  test "an empty message is rejected" do
    sign_in_as users(:marti)
    assert_no_difference "Message.count" do
      post conversation_messages_url(conversations(:vive_thread)), params: { message: { body: "" } }
    end
  end
end
