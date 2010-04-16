# == Schema Information
#
# Table name: messages
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  content_type :string(255)
#  body         :text
#  poster_id    :integer(4)
#  channel_id   :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#  reference_to :integer(4)
#  attachment   :string(255)
#  guid         :string(255)
#  delta        :boolean(1)      default(TRUE), not null
#

class Message < ActiveRecord::Base

  usesnpguid

  belongs_to :poster, :class_name => "Person"
  belongs_to :channel

  validates_presence_of :poster_id
  validates_presence_of :channel_id
  validate_on_create :associations_must_exist

  # Messages shouldn't be changed but in the future could, so protect some
  attr_readonly :poster_id, :channel_id, :guid, :id

  after_save :touch_channel_timestamp

  define_index do
    indexes :title, :sortable => true
    indexes :body

    has :guid
    has :created_at
    has :updated_at

    set_property :field_weights => { 'title' => 5,
                                     'body' => 2 }
    set_property :delta => true
    set_property :enable_star => true
    set_property :min_infix_len => 1
  end

  def to_hash(user=nil, client=nil)
    ref_message = nil
    if self.reference_to
      ref_message = Message.find_by_id(reference_to).andand.guid
    end
    { :id => guid,
      :title => title,
      :body => body,
      :channel => channel.guid,
      :reference_to => ref_message,
      :attachment => attachment,
      :content_type => content_type,
      :poster_id => poster.guid,
      :poster_name => poster.name_or_username,
      :updated_at => updated_at,
      :created_at => created_at
    }
  end

  def to_json(*a)
    return to_hash.to_json(*a)
  end

  def show?(user, client=nil)
    unless channel
      return false
    end
    channel.show? user, client
  end

  private

  def touch_channel_timestamp
    self.channel.touch
  end

  def associations_must_exist
    errors.add("Poster #{poster.id} does not exist.") if poster && !Person.exists?(poster.id)
    errors.add("Channel #{channel.id} does not exist") if channel && !Channel.exists?(channel.id)
    errors.add("Message #{reference_to} does not exist") if reference_to && !Message.exists?(reference_to)
  end

end
