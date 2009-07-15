class Message < ActiveRecord::Base
  
  usesnpguid
  
  belongs_to :poster, :class_name => "Person"
  belongs_to :channel

  validates_presence_of :poster_id
  validates_presence_of :channel_id
  validate :associations_must_exist
  
  private
  
  def associations_must_exist
    errors.add("Poster #{poster.id} does not exist.") if poster && !Person.exists?(poster.id)
    errors.add("Channel #{channel.id} does not exist") if channel && !Channel.exists?(channel.id)
    errors.add("Message #{reference_to.id} does not exist") if reference_to && !Message.exists?(reference_to.id)
  end

end
