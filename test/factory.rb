module Factory

  def self.create_person(attributes = { })
    default_attributes = {

      :username => "kusti",
      :password => "testi",
      :email => "working@address.com",
      :salt => "ZB32fj38ueBG",
      :status_message => "Valid person rocks.",
      :status_message_changed => "2008-08-28T10:58:12+03:00",
      :birthdate => "1940-06-01",
      :gender => "MALE",
      :irc_nick => "pelle",
      :msn_nick => "maison",
      :phone_number => "+358 40 834 7176",
      :description => "About me",
      :website => "http://example.com",

    }

    [ :username, :email ].each do |attribute|
      default_attributes[attribute] = random_prefix(5) + default_attributes[attribute]
    end

    Person.create! default_attributes.merge(attributes)
  end

  def self.create_group(attributes = { })
    default_attributes = {

      :title => "Test title",
      :group_type => "open",
      :creator => create_person

    }

    [ :title ].each do |attribute|
      default_attributes[attribute] = random_prefix(5) + default_attributes[attribute]
    end

    Group.create! default_attributes.merge(attributes)
  end

  private

  def self.random_prefix(length)
      chars_for_key = [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten
      return (0..length).map{ chars_for_key[rand(chars_for_key.length)]}.join
  end

end
