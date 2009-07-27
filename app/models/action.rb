class Action < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :conditions, :through => :condition_action_sets

  validates_presence_of [:action, :data]

  def get_action_id_or_create
    
  end

end
