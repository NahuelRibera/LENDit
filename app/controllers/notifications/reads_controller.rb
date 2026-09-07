module Notifications
  class ReadsController < ApplicationController
    before_action :require_authentication

    def create
      notification = current_user.notifications.find(params[:notification_id])
      notification.mark_read!
      redirect_to notification.target_path
    end
  end
end
