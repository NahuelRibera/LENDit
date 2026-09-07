class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  VERBS = %w[
    rental_requested rental_accepted rental_declined rental_cancelled
    rental_active rental_completed new_message
  ].freeze

  validates :verb, inclusion: { in: VERBS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def message
    case verb
    when "rental_requested" then "#{actor&.first_name} requested to book #{notifiable.listing.title}"
    when "rental_accepted" then "Your request for #{notifiable.listing.title} was accepted"
    when "rental_declined" then "Your request for #{notifiable.listing.title} was declined"
    when "rental_cancelled" then "The booking for #{notifiable.listing.title} was cancelled"
    when "rental_active" then "Your rental for #{notifiable.listing.title} is now active"
    when "rental_completed" then "Your rental for #{notifiable.listing.title} is complete"
    when "new_message" then "#{actor&.first_name} sent you a message"
    else "You have a notification"
    end
  end

  def target_path
    case notifiable
    when Rental then Rails.application.routes.url_helpers.rental_path(notifiable)
    when Message then Rails.application.routes.url_helpers.conversation_path(notifiable.conversation)
    else Rails.application.routes.url_helpers.root_path
    end
  end
end
