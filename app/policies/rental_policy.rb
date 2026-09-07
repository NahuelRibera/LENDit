class RentalPolicy < ApplicationPolicy
  def show?
    participant?
  end

  def create?
    user.present?
  end

  def accept?
    user.present? && user == record.lender
  end
  alias decline? accept?

  def cancel?
    participant?
  end

  private

  def participant?
    user.present? && (user == record.borrower || user == record.lender)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(borrower: user).or(scope.where(lender: user))
    end
  end
end
