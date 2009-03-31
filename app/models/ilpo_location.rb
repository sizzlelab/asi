class IlpoLocation <  ActiveResource::Base


    self.site = "https://ilpo.ext.nokia.com/ilpo-ss/ws/rest"
    self.user = "otastest"
    self.password = "lumi"
    self.timeout = 8
    self.element_name = "user"
    self.collection_name = "users"
    
    def self.get_ilpo_location(ilpo_user_id)
      #puts "#{prefix}users/user/#{ilpo_user_id}/postition"
      #connection.get("#{prefix}users/user/605/postition")
       connection.get("#{prefix}users/user/#{ilpo_user_id}/position")
    end
    
    # def self.create_person(params, cookie)
    #   creating_headers = {"Cookie" => cookie}
    #   response = connection.post("#{prefix}#{element_name}", params.to_json ,creating_headers)
    # end
    # 
    # def self.get_person(id, cookie)
    #   return fix_alphabets(connection.get("#{prefix}#{element_name}/#{id}/@self", {"Cookie" => cookie }))
    # end
    # 
    # def self.search(query, cookie)
    #   return fix_alphabets(connection.get("#{prefix}#{element_name}?search=" + query, {"Cookie" => cookie} ))
    # end
    # 
    # def self.get_friends(id, cookie)
    #   return fix_alphabets(connection.get("#{prefix}#{element_name}/#{id}/@friends", {"Cookie" => cookie }))
    # end
    # 
    # def self.get_pending_friend_requests(id, cookie)
    #   return fix_alphabets(connection.get("#{prefix}#{element_name}/#{id}/@pending_friend_requests", {"Cookie" => cookie }))
    # end
    # 
    # def self.put_attributes(params, id, cookie)
    #   connection.put("#{prefix}#{element_name}/#{id}/@self",{:person => params}.to_json, {"Cookie" => cookie} )   
    # end
    # 
    # def self.update_avatar(image, id, cookie)
    #   connection.put("#{prefix}#{element_name}/#{id}/@avatar", {:file => image}, {"Cookie" => cookie} )
    # end
    # 
    # def self.add_as_friend(friend_id, id, cookie)
    #   connection.post("#{prefix}#{element_name}/#{id}/@friends", {:friend_id => friend_id}.to_json, {"Cookie" => cookie} )
    #   # Rails.cache.delete("person_hash.#{id}")
    #   # Rails.cache.delete("person_hash.#{friend_id}")
    # end
    # 
    # def self.remove_from_friends(friend_id, id, cookie)
    #   connection.delete("#{prefix}#{element_name}/#{id}/@friends/#{friend_id}", {"Cookie" => cookie} )
    #   # Rails.cache.delete("person_hash.#{id}")
    #   # Rails.cache.delete("person_hash.#{friend_id}")
    # end
    # 
    # def self.remove_pending_friend_request(friend_id, id, cookie)
    #   connection.delete("#{prefix}#{element_name}/#{id}/@pending_friend_requests/#{friend_id}", {"Cookie" => cookie} )
    #   # Rails.cache.delete("person_hash.#{id}")
    #   # Rails.cache.delete("person_hash.#{friend_id}")
    # end
    # 
    # #fixes utf8 letters
    # def self.fix_alphabets(json_hash)
    #   #the parameter must be a hash that is decoded from JSON by activeResource messing up umlaut letters
    #   JSON.parse(json_hash.to_json.gsub(/\\\\u/,'\\u'))
    # end
    

end
