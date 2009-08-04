class Parameter
  attr_accessor :childs, :parent, :value, :level
  
  def initialize(value, level)
    self.value = value
    self.level = level
    self.childs = []
  end
  
  def to_list
    retval = "<li> #{self.value} </li>"
    
    unless self.childs.empty?
      retval += "<ul>" 
      self.childs.each do |c|
        retval += c.to_list
      end
      retval += "</ul>"
    end
    
    return retval
  end
  
  def to_table
    name, desc = self.value.split('-')
    
    unless childs.empty?
      retval = "<tr>\n<th class='inner_parameters'><div class='inner_parameters'>#{name}</div></th>\n"
      retval += "<td><table class='inner_parameters'>\n"
      childs.each do |c|
        retval += c.to_table
      end
      retval += "</table></td>\n"
    else
      retval = "<tr>\n<th class='inner_parameters'>#{name}</th>\n"
      retval += "<td>#{desc}</td>\n"
    end
    
    retval += "</tr>\n"
    return retval
  end
  
end
