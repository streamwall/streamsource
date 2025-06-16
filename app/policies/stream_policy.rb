class StreamPolicy < ApplicationPolicy
  def create?
    user.can_modify_streams?
  end
  
  def update?
    user.can_modify_streams? && (record.owned_by?(user) || user.admin?)
  end
  
  def destroy?
    update?
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.active
      end
    end
  end
end