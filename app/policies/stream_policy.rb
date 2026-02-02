# Authorization rules for streams.
class StreamPolicy < ApplicationPolicy
  def create?
    user&.can_modify_streams? || false
  end

  def update?
    user&.can_modify_streams? && (record.owned_by?(user) || user&.admin?)
  end

  def destroy?
    update?
  end

  # Scope for stream visibility.
  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      else
        scope.active
      end
    end
  end
end
