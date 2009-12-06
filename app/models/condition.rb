class Condition < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :actions, :through => :condition_action_sets
  usesguid
  
  validates_presence_of [:condition_type, :condition_value]

  def Condition.get_or_create(options)
    condition = Condition.find(:first, :conditions => options)
    if not condition
      condition = Condition.new(options)
      if condition.save
        return condition
      end
    end
    return condition
  end

  def Condition.find_by_keyword(word)
    regex = "^#{word}$"
    all.detect do |c|
      c.condition_type.match(regex) || c.condition_value.match(regex)
    end
  end

  def to_s
    "#{condition_type}: #{condition_value}"
  end

end
