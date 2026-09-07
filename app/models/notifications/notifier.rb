module Notifications
  # Single call site for creating notifications, invoked from the model
  # methods that already own each event (Rental's transition methods,
  # Message's after_create) — keeps the causal chain grep-able instead of
  # scattering Notification.create! calls across controllers.
  class Notifier
    def self.notify(recipient:, notifiable:, verb:, actor: nil)
      return if recipient.nil? || recipient == actor

      Notification.create!(recipient: recipient, actor: actor, notifiable: notifiable, verb: verb)
    end
  end
end
