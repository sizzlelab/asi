#A class for representing the resource structure of an RESTful rails application
#Sampo Toiva
app_root = File.join(File.dirname(__FILE__), '..', '..', '..') 
require File.join(app_root, 'config', 'environment.rb')

require File.join(File.dirname(__FILE__), 'resource_node.rb')

class ResourceTree
  attr_accessor :resources
  
  def initialize(exceptions = [])
    self.resources = Array.new
    @routes = ActionController::Routing::Routes
    @exceptions = exceptions << ":controller"
    init_structure
  end
  
  def to_s
    self.resources.inject("") { |sum, r|  sum += r.to_s }
  end
  
  def generate_doc
    puts "Generating documentation"
    self.resources.each do |r|
      r.generate_resource_doc
    end
    puts "Done!"
  end
  
  private
  def init_structure
    puts 'Initializing structure'
    read_routes_into_nodes
    create_hierarchy
  end
  
  
  def read_routes_into_nodes
    puts 'Reading routes into nodes'
    @routes.routes.each do |d|
      
      path = d.segments.inject("") { |str,s| str << s.to_s }
      
      unless @exceptions.include?(path.split(/\//)[1]) || @exceptions.include?(path)
        node = ResourceNode.new(path, d.defaults[:controller])
        unless self.resources.include? node
          self.resources << node
        end
        node =  self.resources.find { |r| r == node }
        node.add_method(d.conditions[:method], d.parameter_shell[:action])
      end
    end
  end
  
  def create_hierarchy
    puts 'Creating hierarchy'
    self.resources.sort!
    
    #create parents
    self.resources.each_with_index do |parent, i|
      self.resources.values_at((i+1)..self.resources.size-1).each do |child|
        break unless child.path.match("^#{parent.path}")
        child.parent = parent
      end
    end
    
    #create childs
    self.resources.each do |child|
      if child.parent
        child.parent.add_child(child)
      end
    end
    
    #remove non-root level resources
    self.resources.reject! do |r|
      r.parent
    end
    
    #create levels
    self.resources.each do |r|
      r.create_level 0
    end
    
  end
  
end
