class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_digest.last(10)
  end

  normalizes :email, with: ->(email) { email.strip.downcase }

  has_many :listings, dependent: :restrict_with_error
  has_many :recently_viewed_listings, dependent: :destroy
  has_many :rentals_as_borrower, class_name: "Rental", foreign_key: :borrower_id, inverse_of: :borrower,
    dependent: :restrict_with_error
  has_many :rentals_as_lender, class_name: "Rental", foreign_key: :lender_id, inverse_of: :lender,
    dependent: :restrict_with_error
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, inverse_of: :sender,
    dependent: :restrict_with_error
  has_many :notifications, class_name: "Notification", foreign_key: :recipient_id, inverse_of: :recipient,
    dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :bio, length: { maximum: 500 }
  validate :avatar_is_a_reasonable_image

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    [first_name, last_name].compact_blank.map { |part| part[0] }.join.upcase
  end

  private

  def avatar_is_a_reasonable_image
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, or WEBP image")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5MB")
    end
  end
end
