module StatusBadgesHelper
  LISTING_STATUS_TONES = {
    "draft" => :neutral,
    "published" => :success,
    "paused" => :warning,
    "archived" => :neutral,
  }.freeze

  def listing_status_tone(status)
    LISTING_STATUS_TONES.fetch(status.to_s, :neutral)
  end

  RENTAL_STATUS_TONES = {
    "pending" => :warning,
    "accepted" => :success,
    "active" => :success,
    "completed" => :neutral,
    "declined" => :danger,
    "cancelled" => :danger,
  }.freeze

  def rental_status_tone(status)
    RENTAL_STATUS_TONES.fetch(status.to_s, :neutral)
  end
end
