require 'erb'
require File.join(File.dirname(__FILE__), 'method_doc.rb')

class ResourceNode
  attr_accessor :path, :level, :parent, :documentation, :title, :description
  attr_reader :childs, :methods, :controller

  def initialize(path, controller, description)
    self.path = path
    @childs = Array.new
    @methods = Hash.new
    @controller = controller
    @documentation = Hash.new
    self.description = description

    self.title = self.path.gsub(/:(.*?)\//, '&lt;\1&gt;/')

    class << @documentation
      def each_pair
        [:get, :post, :put, :delete].collect { |m| self.key?(m) ? [m, self[m]] : nil }.compact.each do |a|
          yield a[0], a[1]
        end
      end
    end
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

  # returns the location of the controller that is to be parsed
  def controller_location
    File.join(File.dirname(__FILE__), '..', '..', '..', 'app','controllers', self.controller)
  end

  def name
    path.split(/\//).reject { |x| !x && x.empty? }.last
  end

  def subresource_paths_as_ul_items
    retval = "<li class = level_#{self.level}><tt><%= link_to \"#{self.title}\", \"/doc/#{self.path.delete(':').sub('/','')}\"%></tt></li>"

    unless @childs.empty?
      retval += "<ul>"
      @childs.each do |c|
        retval += "#{c.subresource_paths_as_ul_items}"
      end
      retval += "</ul>"
    end

    return retval
  end

  # returns the location of the controller that is to be parsed
  def controller_location
    #puts self.controller
    File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'controllers', "#{self.controller}_controller.rb")
  end

  def parse_method_doc
    current_state = :none
    current_api_block = nil

    File.open(controller_location).each_with_index do |line, idx|

      if line =~ /=begin rapidoc/
        current_api_block = MethodDoc.new
        current_state = :read_comment

      elsif line =~ /=end/
        current_state = :find_action

      elsif current_state == :read_comment
        line.gsub!(/[']/, '\\\\\'')
        if result = /( *\w+)\:\:\s*(.+)/.match(line)
          @last_variable = result[1].strip
          current_api_block.add_variable(result[1], result[2])
        elsif line.strip != ""
          unless @last_variable == "param"
            eval "current_api_block.#{@last_variable} << '#{line}'"
          else
            puts "ERROR: Parameter description cannot span to multiple lines. Check your syntax."
            puts "Controller: #{controller}, Line: #{idx + 1}"
            Kernel.abort
          end
        end

      elsif current_state == :find_action && !line.empty?
        def_array = line.split(' ').reject { |x| x.empty? }
        if def_array.first == 'def' && self.methods.has_value?(def_array[1])
          self.documentation[self.methods.index(def_array[1])] = current_api_block
          current_state = :none
        elsif def_array.first == 'def' && !self.methods.has_value?(def_array[1])
          current_state = :none
        end

      end

    end
    
    #Find out if there are multiple routes with same action
    self.methods.each_value do |value|
      arr = self.methods.select { |k, v| v == value}
      if self.documentation
        method = nil
        arr.each do |a|
          if self.documentation[a[0]] && ! self.documentation[a[0]].description.empty?
            method = a[0]
          else
            self.documentation[a[0]] = MethodDoc.new
            self.documentation[a[0]].add_variable("description", "See <a href=##{method.to_s.upcase}>#{method.to_s.upcase}</a>")
          end
        end
      end
    end
   
  end

  def generate_resource_doc
    self.methods.each_key do |m|
      self.documentation[m] = nil
    end

    
    self.parse_method_doc

    template = ""

    File.open(File.join(File.dirname(__FILE__), '..', 'templates', 'resource.html.erb.erb')).each { |line| template << line }
    parsed = ERB.new(template).result(binding)

    #self.parent ? view_path = "#{self.parent.path}" : view_path = ""
    view_path = self.path.delete(':')
    view_path = view_path.match(/(.*)\/[^\/]+\/?/)[1]

    FileUtils.mkdir_p File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'views', 'api', view_path )
    File.open(File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'views', 'api', view_path, self.name.delete(':') + ".html.erb"), 'w') do
      |file| file.write parsed
    end

    @childs.each do |c|
      c.generate_resource_doc
    end
  end
end
