class GroupSearchHandle < ActiveRecord::Base

  belongs_to :group

  define_index do
    indexes group(:title), :as => :title, :sortable => true
    indexes group(:description), :as => :description

    set_property :enable_star => true
    set_property :min_infix_len => 1
  end

  class << self
    alias :orig_search :search
  end

  def GroupSearchHandle.search(*a)
    result = orig_search(*a)
    result.collect {|g| g.group }
  end

  def to_hash(user, client)
    group.to_hash(user, client)
  end


  def to_json
    group.to_json
  end


end
