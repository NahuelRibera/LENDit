module ApplicationHelper
  include Pagy::Frontend

  # Active categories, used by both the navbar's mobile drawer and the
  # homepage's "Explore by category" section. Memoized per request.
  def nav_categories
    @nav_categories ||= Category.active.ordered
  end

  # Displays price cents in the original LENDit convention (amount before
  # the currency symbol, e.g. "22.00€"), standardized to two decimals.
  def format_price(cents)
    number_to_currency(cents / 100.0, unit: "€", format: "%n%u", precision: 2)
  end

  def unread_messages_count
    return 0 unless signed_in?

    @unread_messages_count ||= Conversation.unread_for(current_user).count
  end

  def unread_notifications_count
    return 0 unless signed_in?

    @unread_notifications_count ||= current_user.notifications.unread.count
  end
end
