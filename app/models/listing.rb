class Listing < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  CONDITIONS = %w[new like_new good fair].freeze

  # Which statuses a given target status may be reached from. Archiving is
  # allowed from any non-archived state; there is no way back to draft.
  TRANSITIONS = {
    "published" => %w[draft paused],
    "paused" => %w[published],
    "archived" => %w[draft published paused],
  }.freeze

  belongs_to :user
  belongs_to :category

  has_many :listing_images, -> { order(:position) }, dependent: :destroy, inverse_of: :listing
  has_many :rentals, dependent: :restrict_with_error
  has_many :availability_blocks, dependent: :destroy

  enum :status, { draft: "draft", published: "published", paused: "paused", archived: "archived" }, validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true, length: { maximum: 4000 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :condition, inclusion: { in: CONDITIONS }
  validates :city, presence: true, length: { maximum: 100 }

  scope :published, -> { where(status: "published") }
  scope :recent, -> { order(created_at: :desc, id: :desc) }

  # Marketplace discovery (home, browse/search, categories, related items)
  # is a borrowing context: a user should never be offered their own
  # listing to rent. Owner-facing screens (My Products, public profile,
  # incoming rental requests) intentionally do NOT use this scope.
  scope :available_to, ->(user) { user ? where.not(user_id: user.id) : all }

  # Price is stored as integer cents (see architecture notes on money);
  # this virtual accessor lets forms work in whole euros.
  def price
    price_cents && price_cents / 100.0
  end

  def price=(value)
    self.price_cents = value.present? ? (value.to_f * 100).round : nil
  end

  def primary_image
    listing_images.find(&:is_primary?) || listing_images.first
  end

  def condition_label
    condition.to_s.tr("_", " ").capitalize
  end

  def publish! = transition_to!("published")
  def pause! = transition_to!("paused")
  def reactivate! = transition_to!("published")

  def archive!
    if rentals.blocking.exists?
      raise InvalidTransitionError, "Cannot archive a listing with an active or upcoming booking"
    end

    transition_to!("archived")
  end

  private

  def transition_to!(new_status)
    allowed_from = TRANSITIONS.fetch(new_status) do
      raise InvalidTransitionError, "#{new_status} is not a valid listing status"
    end

    unless allowed_from.include?(status)
      raise InvalidTransitionError, "Cannot move a listing from #{status} to #{new_status}"
    end

    update!(status: new_status)
  end
end
