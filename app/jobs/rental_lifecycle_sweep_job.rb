# Moves rentals through their date-driven transitions: an accepted rental
# becomes active once its start date arrives, and an active rental becomes
# completed the day after its end date. Intended to run on a schedule
# (e.g. hourly, via whatever scheduler the deployment target provides —
# Heroku Scheduler, cron + whenever, etc.); Account::LendsController and
# Account::BorrowsController also call it inline so the demo app behaves
# correctly without a real scheduler running.
class RentalLifecycleSweepJob < ApplicationJob
  queue_as :default

  def perform
    Rental.accepted.where(start_date: ..Date.current).find_each(&:activate!)
    Rental.active.where(end_date: ...Date.current).find_each(&:complete!)
  end
end
