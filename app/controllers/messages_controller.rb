class MessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_conversation

  def create
    message = @conversation.messages.new(message_params.merge(sender: current_user))

    if message.save
      @conversation.mark_read_for!(current_user)
      redirect_to conversation_path(@conversation)
    else
      redirect_to conversation_path(@conversation), alert: message.errors.full_messages.to_sentence
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
    authorize @conversation, :create_message?
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
