class PasswordMailer < ApplicationMailer
  # No real SMTP provider is configured for this portfolio project (out of
  # scope, see architecture notes), so the reset link is also logged —
  # check log/development.log after requesting a reset locally.
  def reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    @reset_url = edit_password_reset_url(token: @token)
    Rails.logger.info "[PasswordMailer] Reset link for #{user.email}: #{@reset_url}"
    mail to: user.email, subject: "Reset your LENDit password"
  end
end
