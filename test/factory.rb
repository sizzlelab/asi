module Factory

  def self.metafactory(klass, default_attributes, prefix_attributes = [])
    class_eval(%{
      def self.create_#{klass.name.downcase}(options = { :prefix => true, :save => true }, attributes = { })
        default_attributes = #{default_attributes}

        #{prefix_attributes.inspect}.each do |attribute|
          default_attributes[attribute] = random_prefix(5) + default_attributes[attribute]
        end

        if options[:save]
          #{klass}.create! default_attributes.merge(attributes)
        else
          #{klass}.create! default_attributes.merge(attributes) rescue #{klass}.create default_attributes.merge(attributes)
        end
      end

      def self.create_example_#{klass.name.downcase}
        self.create_#{klass.name.downcase}(:prefix => false, :save => false)
      end

    })
  end

  metafactory(Person, %{{

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
      :website => "http://example.com"

  }}, [ :username, :email ])

  metafactory(Group, %{{

      :title => "An example group",
      :description => "Groups can have descriptions. This is an example.",
      :group_type => "open",
      :creator => create_person(options)

  }})

  metafactory(Location, %{ {
      :latitude => 60.163389841749,
      :longitude => 24.857125767506,
      :accuracy => 58.0,
      :label => "Otaniemen Alepa"
  }})

  private

  def self.random_prefix(length)
      chars_for_key = [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten
      return (0..length).map{ chars_for_key[rand(chars_for_key.length)]}.join
  end

end
