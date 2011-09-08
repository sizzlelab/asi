class ActiveRecord::Base        
  def typestr
    self.class.to_s
  end
end
