class ListingImage < ApplicationRecord
  belongs_to :listing
  has_one_attached :file

  validates :file, presence: true
  validate :file_is_a_reasonable_image

  scope :ordered, -> { order(:position) }

  private

  def file_is_a_reasonable_image
    return unless file.attached?

    unless file.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:file, "must be a PNG, JPEG, or WEBP image")
    end

    if file.byte_size > 8.megabytes
      errors.add(:file, "must be smaller than 8MB")
    end
  end
end
