# == Schema Information
#
# Table name: notes
#
#  id          :bigint           not null, primary key
#  content     :text             not null
#  user_id     :bigint           not null
#  notable_type :string          not null
#  notable_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Note < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :notable, polymorphic: true
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :user, presence: true
  validates :notable, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_streams, -> { where(notable_type: 'Stream') }
  scope :for_streamers, -> { where(notable_type: 'Streamer') }
  
  # Instance methods
  def owned_by?(user)
    self.user_id == user&.id
  end
  
  def truncated_content(limit = 100)
    content.length > limit ? "#{content[0...limit]}..." : content
  end
end