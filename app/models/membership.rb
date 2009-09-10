class Membership < ActiveRecord::Base

  belongs_to :person
  belongs_to :group
  belongs_to :inviter, :class_name => "Person"
  
  def to_json
    hash = { }
    %w(accepted_at created_at updated_at group_id admin_role status).each do |attribute|
      hash[attribute] = send(attribute)
    end
    hash["inviter_id"] = inviter.andand.guid
    hash["person_id"] = person.guid
    hash.to_json
  end

  def status
    return "active" if accepted_at
    return "invited" if inviter_id and not accepted_at
    return "requested" if not inviter_id and not accepted_at
  end
  
end
