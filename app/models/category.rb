class Category < ApplicationRecord
  has_many :listings, dependent: :restrict_with_error

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :icon_key, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
