# This class holds methods about a doc.
class MethodDoc
  attr_accessor :scope, :content
  
  def initialize(type)
    @scope = type
    @variables = []
    @content = ""
    @codes = []
  end
  
  
  def add_variable(name, value)
  
    @variables << value and return if name == "param"
    @codes << value and return if name == "return_code"
    
    eval("@#{name}= \"#{value}\"")
  end
  
  def get_binding
    binding
  end
end
