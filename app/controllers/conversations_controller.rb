class ConversationsController < ApplicationController
  before_action :require_authentication

  def index
    @conversations = load_conversations
  end

  def show
    @conversation = Conversation.find(params[:id])
    authorize @conversation
    @conversation.mark_read_for!(current_user)
    @conversations = load_conversations
    @message = Message.new
  end

  private

  def load_conversations
    policy_scope(Conversation)
      .includes(:listing, :user_one, :user_two, messages: :sender, conversation_reads: [])
      .sort_by { |conversation| conversation.messages.map(&:created_at).max || conversation.created_at }
      .reverse
  end
end
