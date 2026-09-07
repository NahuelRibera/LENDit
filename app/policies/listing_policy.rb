class ListingPolicy < ApplicationPolicy
  # Anyone can view a published listing; only the owner can preview their
  # own draft/paused/archived listing.
  def show?
    record.published? || owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end
  alias edit? update?
  alias manage_status? update?
  alias manage_images? update?

  private

  def owner?
    user.present? && user == record.user
  end

  class Scope < Scope
    def resolve
      scope.published
    end
  end
end
