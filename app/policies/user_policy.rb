class UserPolicy < ApplicationPolicy
  # Public profiles are visible to anyone, including guests.
  def show? = true

  def edit?
    user == record
  end
  alias update? edit?
end
