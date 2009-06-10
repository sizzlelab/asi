require 'test_helper'
require 'json'

class GroupsTest < ActionController::IntegrationTest
  fixtures :groups, :people, :clients

  def test_open_group
    new_session do |ossi|
      ossi.logs_in_with( { :username => people(:valid_person).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi" })
      group_id = ossi.creates_group_with( { :title => "My first group", :type => "open", :description => "Testing..." } )
      ossi.logs_out

      ossi.logs_in_with( {:username => people(:test).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi"})
      group_ids = ossi.lists_public_groups
      ossi.joins_group(people(:test).id, group_ids[0])
      ossi.leaves_group(people(:test).id, group_ids[0])
      ossi.logs_out
    end
  end

  def test_closed_group
    new_session do |ossi|
      ossi.logs_in_with( { :username => people(:valid_person).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi" })
      group_id = ossi.creates_group_with( { :title => "My first closed group", :type => "closed", :description => "Testing..." } )
      requests = ossi.lists_membership_requests(group_id)
      assert requests.empty?, "New group has pending requests"
      ossi.logs_out

      ossi.logs_in_with( {:username => people(:test).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi"})
      ossi.joins_group(people(:test).id, group_id)
      ossi.logs_out     

      ossi.logs_in_with( { :username => people(:valid_person).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi" })
      requests = ossi.lists_membership_requests(group_id)
      assert_equal 1, requests.size
      #ossi.accepts_member(requests[0], group_id)
    end
  end

  private

  def new_session
    open_session do |sess|
      sess.extend(COSTestingDSL)
      yield sess if block_given?
    end
  end
end
