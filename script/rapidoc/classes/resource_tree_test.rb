#!/usr/bin/ruby
require FileUtils"
require File.join(File.dirname(__FILE__), 'resource_tree.rb')

Dir.new(File.join(File.dirname(__FILE__), '..', 'test', 'views', 'apidoc')).each { |x| puts x unless x == '.' || x == '..'}
tree = ResourceTree.new ['/', 'api', 'doc', 'admin', 'coreui', 'tutorial', 'test', 'transactions']
#puts tree.inspect
puts tree
tree.generate_doc
