class Array

  attr_accessor :count_available

  def filter_paginate!( per_page, page = 1 )
    if !per_page || !page || per_page.to_i < 1 || page.to_i < 1
      return self.reject!{ |a| ! yield a }
    end
    count = 0
    count_to = per_page.to_i * page.to_i
    count_from = count_to - per_page.to_i
    ar = Array.new(self)
    ar.each do |a|
      if yield a
        if count < count_from || count >= count_to
          self.delete a
        end
        count += 1
      else
        self.delete a
      end
    end
    if !self.count_available
      self.count_available = count
    end
    return self
  end

#    def self.filter_paginate!(function = nil, options = {})
#      self = filter_paginage(function, options)
#    end

end
