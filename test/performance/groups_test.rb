require 'test_helper'
require 'performance_test_help'

class GroupsTest < ActionController::PerformanceTest
  # Replace this with your real tests.
  def test_list
    get '/groups/@public'
  end
  
  def test_list_paginate
    get '/groups/@public', {:per_page => 2, :page => 2}
  end
end
