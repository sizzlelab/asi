# == Schema Information
#
# Table name: group_search_handles
#
#  id       :integer(4)      not null, primary key
#  group_id :string(255)
#  delta    :boolean(1)      default(TRUE), not null
#

#
# A kludge to accommodate searching of groups
#
class GroupSearchHandle < ActiveRecord::Base
  belongs_to :group

  define_index do
    indexes group(:title), :as => :title, :sortable => true
    indexes group(:description), :as => :description

    set_property :enable_star => true
    set_property :min_infix_len => 1
    set_property :delta => true
  end

  class << self
    alias :orig_search :search
  end

  def GroupSearchHandle.search(*a)
    result = orig_search(*a)
    result.collect {|g| g.group }
  end

  def show?(person, client=nil)
    group.show?(person, client)
  end

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(user=nil, client=nil)
    group.to_hash(user, client)
  end

  def typestr
    "Group"
  end
end
