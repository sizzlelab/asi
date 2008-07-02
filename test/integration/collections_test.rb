require 'test_helper'
require 'json'

class CollectionsTest < ActionController::IntegrationTest
  fixtures :collections, :people, :clients, :connections

  def test_find_collection
    new_session do |ossi|
      ossi.logs_in_with( {:username => people(:test).username, :password => "testi", :client_name => clients(:one).name, :client_password => "testi"})
      collection_id = ossi.finds_collections :client_id => clients(:one).id
      options = { :client_id => clients(:one).id, :id => collection_id }
      
      ossi.gets_collection options
      ossi.adds_text_to_collection options
      ossi.deletes_collection options
      ossi.logs_out
    end
  end

  def test_create_and_delete_collection
    new_session do |ossi|
      ossi.logs_in_with( {:username => people(:test).username, :password => "testi", :client_name => clients(:one).name, :client_password => "testi"})
      collection_id = ossi.creates_collection(:client_id => clients(:one).id)
      options = { :client_id => clients(:one).id, :id => collection_id }
      ossi.adds_text_to_collection options
      ossi.deletes_collection options
      ossi.tries_to_find_deleted_collection options
      ossi.logs_out
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
