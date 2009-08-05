# This class holds methods about a doc.
require File.join(File.dirname(__FILE__), 'parameter.rb')

class MethodDoc
  attr_accessor :parameters, :return_codes
 
  def initialize
    @parameters = []
    @return_codes = []
  end
  
  def add_variable(name, value)
    
    if level = name.index('param')
      level = level/2
      
      param = Parameter.new(value, level)
      
      if level == 0
        @current_parent = param
        parameters << param
      elsif level == @current_parent.level
        @current_parent = @current_parent.parent
        make_child(param)
      elsif level < @current_parent.level
        @current_parent.level.times do 
          @current_parent = @current_parent.parent
        end
        make_child(param)
      elsif level == @current_parent.level + 1
        make_child(param)
      elsif level == @current_parent.level + 2
        @current_parent = last
        make_child(param)
      else
        puts "\nERROR: No parent found for #{name.strip}: #{value}. Check your syntax." 
        Kernel.abort
      end
      
      @last = param
      return
    end
    
    @return_codes << value and return if name == 'return_code'
    
    eval("@#{name}= '#{value}\n'")
  end
  
  def make_child(param)
    @current_parent.childs << param
    param.parent = @current_parent
  end
 
  def method_missing(methId)
    eval("@#{methId}")
  end
  
  def get_binding
    binding
  end
  
end
