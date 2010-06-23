class AuthenticationServiceLink < ActiveRecord::Base
  belongs_to :person
  validates_uniqueness_of :link
end
