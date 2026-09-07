module Notifications
  class ReadAllsController < ApplicationController
    before_action :require_authentication

    def create
      current_user.notifications.unread.update_all(read_at: Time.current)
      redirect_back fallback_location: notifications_path
    end
  end
end
