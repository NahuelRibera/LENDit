require "test_helper"

class ListingConversationsControllerTest < ActionDispatch::IntegrationTest
  test "messaging the owner finds or creates the listing+pair conversation" do
    sign_in_as users(:nahuel)

    assert_difference "Conversation.count", 1 do
      post listing_conversation_url(listings(:vive))
    end

    conversation = Conversation.last
    assert_redirected_to conversation_path(conversation)
    assert conversation.participant?(users(:nahuel))
    assert conversation.participant?(users(:marti)) # vive's owner
  end

  test "messaging the owner again reuses the same conversation" do
    sign_in_as users(:nahuel)
    post listing_conversation_url(listings(:vive))
    first = Conversation.last

    assert_no_difference "Conversation.count" do
      post listing_conversation_url(listings(:vive))
    end

    assert_equal first, Conversation.last
  end

  test "cannot message yourself about your own listing" do
    sign_in_as users(:marti)
    post listing_conversation_url(listings(:vive))
    assert_redirected_to listing_path(listings(:vive))
  end
end
