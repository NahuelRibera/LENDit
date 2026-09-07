class Conversation < ApplicationRecord
  belongs_to :listing
  belongs_to :user_one, class_name: "User"
  belongs_to :user_two, class_name: "User"

  has_many :messages, -> { order(:created_at) }, dependent: :destroy, inverse_of: :conversation
  has_many :conversation_reads, dependent: :destroy

  validate :users_are_ordered_and_distinct

  # A conversation is scoped to one listing and a normalized (low id, high
  # id) pair of users, so the same two people discussing the same listing
  # always land back in the same thread, across multiple rentals — never
  # one conversation per rental.
  def self.between(user_a, user_b, listing:)
    low, high = [user_a, user_b].sort_by(&:id)
    find_or_create_by!(listing: listing, user_one: low, user_two: high)
  end

  def other_participant(user)
    user == user_one ? user_two : user_one
  end

  def participant?(user)
    user.present? && (user == user_one || user == user_two)
  end

  def unread_for?(user)
    last_message_at = messages.map(&:created_at).max
    return false if last_message_at.nil?

    read = conversation_reads.detect { |r| r.user_id == user.id }
    read.nil? || read.last_read_at.nil? || read.last_read_at < last_message_at
  end

  def mark_read_for!(user)
    record = conversation_reads.find_or_initialize_by(user: user)
    record.update!(last_read_at: Time.current)
  end

  # SQL-based unread count for the navbar badge — avoids loading every
  # conversation into Ruby just to check read state on every page.
  def self.unread_for(user)
    join_sql = sanitize_sql_array([<<~SQL.squish, user.id])
      LEFT JOIN conversation_reads ON conversation_reads.conversation_id = conversations.id
        AND conversation_reads.user_id = ?
    SQL

    where("conversations.user_one_id = :id OR conversations.user_two_id = :id", id: user.id)
      .joins("INNER JOIN messages ON messages.conversation_id = conversations.id")
      .joins(join_sql)
      .where("messages.created_at > COALESCE(conversation_reads.last_read_at, '-infinity')")
      .distinct
  end

  private

  def users_are_ordered_and_distinct
    return unless user_one_id && user_two_id

    errors.add(:base, "Conversation participants must be different users") if user_one_id == user_two_id
    errors.add(:base, "user_one_id must be less than user_two_id") if user_one_id > user_two_id
  end
end
