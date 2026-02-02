# == Schema Information
#
# Table name: jwt_denylists
#
#  id         :bigint           not null, primary key
#  jti        :string           not null
#  exp        :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylists"
end
