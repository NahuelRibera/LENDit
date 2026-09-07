class ConversationPolicy < ApplicationPolicy
  def show?
    participant?
  end

  def create_message?
    participant?
  end

  private

  def participant?
    user.present? && record.participant?(user)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(user_one: user).or(scope.where(user_two: user))
    end
  end
end
