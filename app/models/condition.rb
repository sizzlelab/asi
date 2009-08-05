class Condition < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :actions, :through => :condition_action_sets

  validates_presence_of [:condition_type, :condition_value]

  def Condition.get_or_create(options)
    condition = Condition.find(:first, :conditions => { :condition_type => options[:condition_type], :condition_value => options[:condition_value] })
    if condition.length == 0
      condition = Condition.new(:condition_type => options[:condition_type], :condition_vale => options[:cocndition_value])
      if condition.save
        return condition
      end
    end
    return condition
  end
end
