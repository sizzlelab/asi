require 'fileutils'

require File.join(File.dirname(__FILE__), 'classes', 'resource_tree.rb')
require File.join(File.dirname(__FILE__), 'classes', 'doc_util.rb')

tree = ResourceTree.new ['/', 'confirmation', 'api', 'doc', 'admin', 'coreui', 'tutorial', 'test', 'transactions', 'people/change_password', 'people/reset_password', 'system']

FileUtils.rm_rf(File.join(FileUtils.pwd, 'app', 'views', 'api'))

tree.generate_doc
