class NotificationsController < ApplicationController
  before_action :require_authentication

  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
  end
end
