# == Schema Information
#
# Table name: bin_objects
#
#  id           :integer(11)      not null, primary key
#  name         :string(255)
#  data         :text
#  content_type :string(255)
#  orig_name    :string(255)
#  poster_id    :integer(11)
#  created_at   :datetime
#  updated_at   :datetime
#  guid         :string(255)
#

class BinObject < ActiveRecord::Base

  usesnpguid

  belongs_to :poster, :class_name => "Person"

  validates_presence_of :poster_id
  validate :associations_must_exist, :on => :create

  attr_readonly :poster_id, :guid, :id

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(*a)
    {
      :id => guid,
      :name => name,
      :content_type => content_type,
      :orig_name => orig_name,
      :poster_id => poster.guid,
      :poster_name => poster.name_or_username,
      :updated_at => updated_at,
      :created_at => created_at
    }
  end

  def associations_must_exist
    errors.add("Poster #{poster.id} does not exist.") if poster && !Person.exists?(poster.id)
  end

end
