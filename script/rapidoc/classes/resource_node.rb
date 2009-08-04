require 'erb'

class ResourceNode
  attr_accessor :path, :level, :parent, :documentation
  attr_reader :childs, :methods, :controller

  def initialize(path, controller)
    self.path = path
    @childs = Array.new
    @methods = Hash.new
    @controller = controller
  end
 
  def == (object)
    self.path == object.path
  end
  
  def <=> (object)
    self.path <=> object.path
  end
  
  def to_s
    retval = "#{"  " * self.level} #{self.path}" 
    methods.each_pair { |key, value| retval += " [Method: #{key.to_s.upcase} Action: #{value.to_s} Controller: #{@controller}] "}
    retval += "\n"
    
    @childs.each do |c|
      retval += c.to_s
    end
    
    return retval
 end
  
  def add_child(child)
    @childs << child
  end
  
  def add_method(method, action)
    @methods[method] = action
  end
  
  def include_child?(child)
    @childs.include?(child)
  end
  
  def create_level(level)
    @childs.each do |child|
      child.create_level(level+1)
    end
    self.level = level
  end
  
  def get_binding
    binding
  end
  
  # returns the location of the controller that is to be parsed
  def controller_location
    File.join(File.dirname(__FILE__), '..', '..', '..', 'app','controllers', self.controller)
  end
  
  def name
    path.split(/\//).reject { |x| !x && x.empty? }.last
  end
  
  def generate_resource_doc
    template = ""
    File.open(File.join(File.dirname(__FILE__), '..', 'templates', 'resource.html.erb.erb')).each { |line| template << line }
    parsed = ERB.new(template).result(binding)
    File.open(File.join(File.dirname(__FILE__), '..', 'test', 'views', 'apidoc', self.name + ".html.erb"), 'w') { |file| file.write parsed }
    
    @childs.each do |c|
      c.generate_resource_doc
    end
    
  end
end
