#!/usr/bin/ruby
require 'fileutils'

require File.join(File.dirname(__FILE__), 'resource_tree.rb')
require File.join(File.dirname(__FILE__), 'doc_util.rb')

tree = ResourceTree.new ['/', 'api', 'doc', 'admin', 'coreui', 'tutorial', 'test', 'transactions', 'people/change_password', 'people/reset_password']

puts tree
