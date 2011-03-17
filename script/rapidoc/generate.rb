# include the rails test environment, this sets RAILS_ENV to test
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../../config/environment', __FILE__)

# load in rails rake tasks
require ::File.expand_path('../../../config/application', __FILE__)
require 'rake'
Asi::Application.load_tasks

require 'erb'
require 'rdoc/markup/to_html'
require ::File.expand_path('../classes/doc_util',  __FILE__)

module RAPIDoc
  class RAPIDoc
    @@excludes = {
      'application' => '*',
      'admin/feedbacks' => '*',
      'coreui/profile' => '*',
      'coreui/privacy' => '*',
      'doc' => '*',
      'api' => '*',
      'rules' => '*',
      'people' => ['change_password', 'reset_password']
    }

    def initialize
      @file_info_cache = {}
      @route_info = {}

      # parser which will turn rdoc comments onto RDoc::Document structure
      @comment_parser = RDoc::Markup::ToHtml.new
    
      @output_template = nil
    end

    def main()
      # this has the effect of clearing the test db so that the
      # factory can run without confilicts.
      # TODO: is there a better way of doing this?
      Rake::Task['db:test:prepare'].invoke()

      # get a list of controllers
      Rails.application.routes.routes.each do |r|
        if use_route?(r)

          # convert the controller to a filename
          fn = get_controller_file(r.requirements[:controller])

          # parse the controller file if it has not already been parsed
          if !@file_info_cache[fn]
            rdoc = RDoc::RDoc.new
            rdoc.options = RDoc::Options.new
            file_info = rdoc.parse_files [fn]

            unless file_info[0].classes[0].nil?
              @file_info_cache[fn] = file_info[0].classes[0]
            end
          end
          
          # the needed parts of the route
          action = r.requirements[:action]
          controller = r.requirements[:controller]
          verb = r.verb.to_s.upcase
          path = r.path.to_s.gsub(/\(\.:format\)/, '')
          comment = get_comment(fn, action)

          # create a route info hash
          route_info = {
            :action => action,
            :controller => controller,
            :verb => verb,
            :path => path,
            :comment => comment,
            :subresources => []
          }

          # a path is a basically a hash of verbs
          if !@route_info[path]
            @route_info[path] = RAPIDocRouteInfoList.new(path, DocUtil.format_resource_name(path))
          end

          # store it using the verb key
          @route_info[path].verbs[verb] = route_info
        end
      end

      # get the output template
      file = File.open(::File.expand_path('../templates/resource.html.erb.erb',  __FILE__), "rb")
      @output_template = file.read

      # sort the paths and generate the docs
      @route_info.keys.sort.each do |path|
        puts path

        @route_info[path].breadcrumb_hash = get_breadcrumb_hash(path)
        @route_info[path].subresources = get_subresources(path)
        @route_info[path].subresources_index = calculate_resource_tree(path)

        parsed = ERB.new(@output_template).result(@route_info[path].get_binding)

        output_root = ::File.expand_path('../../../app/views/api',  __FILE__)
        path_components = File.join(output_root, path.delete(':')).split('/')

        dir_path = DocUtil.arr_to_path(path_components[0..-2])
        file_path = File.join(dir_path, path_components[-1] + ".html.erb")

        FileUtils.mkdir_p(dir_path)
        File.open(file_path, 'w') do
          |file| file.write parsed
        end
      end
    end

    #----------------------------------------------------------------------------
    # Helper methods

    def use_route?(r)
      if r.requirements[:controller]
        if @@excludes.has_key?(r.requirements[:controller])
          if @@excludes[r.requirements[:controller]] == '*' or @@excludes[r.requirements[:controller]].include?(r.requirements[:action])
            return false
          end
        end
        if r.verb
          return true
        end
      end
      return false
    end

    # convert a controller symbol into a filename
    def get_controller_file(controller)
      ::File.expand_path("../../../app/controllers/#{controller}_controller.rb", __FILE__)
    end

    # find the rdoc comment structure for the given action from the given file
    def get_comment(filename, action)
      DocUtil.extract_info(@comment_parser.parse(find_raw_comment_for(filename, action)))
    end

    # get the raw comment text for the given action from the the given filename
    def find_raw_comment_for(filename, action)
      @file_info_cache[filename].method_list.each do |m|
        if m.name == action
          return m.comment
        end
      end
      return nil
    end

    # create a hash of the sub-components of a path,
    # the key is the sub-component name, the value is a full sub-path (which can be rendered as a link)
    # if the value if nil, it mean there is no such sup-path
    def get_breadcrumb_hash(path)
      ret = {}
      path_components = DocUtil.path_to_arr(path)

      path_components.each_index do |i|
        next if i == 0

        sub_path = DocUtil.arr_to_path(path_components[0..i])
        if @route_info.keys.include?(sub_path)
          ret[path_components[i]] = sub_path
        else
          ret[path_components[i]] = nil
        end
      end
      return ret
    end

    # get all the sub-paths of a given path
    def get_subresources(path)
      ret = []
      @route_info.keys.sort.each do |sub|
        if RAPIDoc.is_sub_path(path, sub)
          ret << sub
        end
      end
      return ret
    end

    # returns an array representing a tree of the resource nodes
    def calculate_resource_tree(path)
      ret = []
      resources = @route_info[path].subresources

      return ret if resources.empty?

      parent = {}
      resources.each_index do |i|
        if i == 0
          ret << i
          parent[i] = ret

        elsif RAPIDoc.is_child(resources, i-1, i)
          # start a sub-array
          s = [i]

          # add to immediate parent
          # (this assumes that the resources are ordered correctly)
          parent[i-1] << s
          parent[i] = s

        else
          # back up the tree to find nearest sibling
          (0..i-1).reverse_each do |j|
            if j == 0 or RAPIDoc.is_sibling(resources, i, j)
              parent[j] << i
              parent[i] = parent[j]
              break
            end
          end
        end
      end
      return ret
    end

    def self.is_sub_path(path, sub)
      sub.starts_with?(path) and sub != path
    end

    # true if b is child of a
    def self.is_child(resources, a, b)
      is_sub_path(resources[a], resources[b])
    end

    # true if b is sibling of a
    def self.is_sibling(resources, a, b)
      a = DocUtil.path_to_arr(resources[a])
      a.pop
      b = DocUtil.path_to_arr(resources[b])
      b.pop
      a == b
    end

  end

  # stores information about a route which is passed to the template for rendering
  class RAPIDocRouteInfoList
    attr_accessor :path, :name, :verbs, :breadcrumb_hash, :subresources, :subresources_index

    def initialize(path, name=nil)
      @path = path
      @name = name || path
      @verbs = {}
      @breadcrumb_hash = []
      @subresources = []
      @subresources_index = []
    end

    def get_binding
      binding
    end
  end
end


# execute main()
r = RAPIDoc::RAPIDoc.new().main()



