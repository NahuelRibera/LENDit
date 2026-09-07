class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_is_a_participant

  after_create_commit :broadcast_message, :notify_recipient

  private

  def sender_is_a_participant
    errors.add(:sender, "must be a participant in the conversation") if conversation && !conversation.participant?(sender)
  end

  def broadcast_message
    broadcast_append_to conversation, target: "messages", partial: "messages/message", locals: { message: self }
  end

  def notify_recipient
    Notifications::Notifier.notify(
      recipient: conversation.other_participant(sender),
      actor: sender,
      notifiable: self,
      verb: "new_message"
    )
  end
end
