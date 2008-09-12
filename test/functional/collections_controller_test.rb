require 'test_helper'
require 'json'

class CollectionsControllerTest < ActionController::TestCase

  def setup
    @controller = CollectionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_index
    get :index, { :app_id => clients(:one).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["collections"]
    json = JSON.parse(@response.body)
    assert_not_nil json["entry"]

    # Should only return collections relevant to this client
    for collection in assigns["collections"]
      assert_equal(collection.client, clients(:one))
    end

    # Should not crash on a nonexistent client
    get :index, { :app_id => -1, :format => 'json' }
    assert_response :forbidden
    assert_nil assigns["collection"]
  end

  def test_show

    # Should not show without logging in
    get :show, { :app_id => clients(:two).id, :id => collections(:one).id, :format => 'json' }

    assert_response :forbidden
    assert_nil assigns["collection"]


    # Should show a collection belonging to the client
    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }

    assert_response :success
    assert_not_nil assigns["collection"]
    json = JSON.parse(@response.body)
    assert_not_nil json["id"]

    # Should not show a collection belonging to another client
    get :show, { :app_id => clients(:two).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session2).id }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should not show a collection belonging to another user
    get :show, { :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session2).id }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should show a collection belonging to a connection of the user
    get :show, { :app_id => clients(:one).id, :id => collections(:three).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }

    assert people(:valid_person).contacts.include?(collections(:three).owner)
    assert_response :success
    assert_not_nil assigns["collection"]
    json = JSON.parse(@response.body)
    assert_not_nil json["id"]

    # Should not show a collection beloning to a requested connection
    get :show, { :app_id => clients(:one).id, :id => collections(:four).id, :format => 'json' }, 
               { :client => clients(:one).id, :user => people(:valid_person) }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should not crash on a nonexistent collection
    get :show, { :app_id => clients(:one).id, :id => 2340982349078, :format => 'json' }, 
               { :client => clients(:one).id }
    assert_response 404
    assert_nil assigns["collection"]

    # Should not crash on a nonexistent client
    get :show, { :app_id => -1, :id => 2340982349078, :format => 'json' }
    assert_response 403
    assert_nil assigns["collection"]
   
  end

  def test_create
    # With an owner and a client
    post :create, { :app_id => clients(:one).id, :format => 'json', :owner => people(:valid_person).id }, 
                  { :session_id => sessions(:session1).id, :client => clients(:one).id }
    assert_response :created
    assert_not_nil assigns["collection"]
    assert_equal(assigns["collection"].owner, people(:valid_person))
    assert_equal(assigns["collection"].client, clients(:one))
    json = JSON.parse(@response.body)
    assert_not_nil json["id"]

    # With only a client
    post :create, { :app_id => clients(:one).id, :format => 'json'}, 
                  { :client => clients(:one).id }
    assert_response :created
    assert_not_nil assigns["collection"]
    assert_nil assigns["collection"].owner
    assert_equal(assigns["collection"].client, clients(:one))
    json = JSON.parse(@response.body)
    assert_not_nil json["id"]

    # With only an owner
    post :create, { :format => 'json' }, 
                  { :owner => people(:valid_person).id }
    assert_response :forbidden

    # With neither
    post :create, { :format => 'json' }
    assert_response :forbidden
  end

  def test_delete
    # Should delete a collection belonging to the client
    delete :delete, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
                    { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)

    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :not_found

    # Should not allow POST
    post :delete, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
                  { :session_id => sessions(:session1).id }
    assert_response :method_not_allowed

    # Should not delete a collection belonging to another client
    delete :delete, { :id => collections(:two).id, :format => 'json' }, 
                    { :session_id => sessions(:session1).id }
    assert_response :forbidden

    # Should not delete a collection belonging to another user
    delete :delete, { :id => collections(:two).id, :user => people(:valid_person).id, :format => 'json' }, 
                    { :session_id => sessions(:session2).id }
    assert_response :forbidden

    # Should not delete a collection belonging to a friend
    delete :delete, { :app_id => clients(:one).id, :id => collections(:three).id, :format => 'json' }, 
                    { :client => collections(:three).client.id, :user => people(:valid_person).id }

    assert people(:valid_person).contacts.include?(collections(:three).owner)
    assert_response :forbidden
  end

  def test_add_text
    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :success
    old_item_count = assigns["collection"].items.count
    json = JSON.parse(@response.body)
    
    # Should be able to add to a collection belonging to the client
    post :add, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json', 
                 :title => "The Engine", :content_type => "text/plain", :body => "Lorem ipsum dolor sit amet." },
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(old_item_count+1, assigns["collection"].items.count)
    json = JSON.parse(@response.body)
  end

  def test_add_image
    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :success
    old_item_count = assigns["collection"].items.count
    json = JSON.parse(@response.body)

    # Should be able to add to a collection belonging to the client
    post :add, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json', 
                 :file => fixture_file_upload("Bison_skull_pile.png","image/png") },
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(old_item_count+1, assigns["collection"].items.count)
    json = JSON.parse(@response.body)
  end    

  def test_metadata
    put :update, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json',
                   :collection => { :metadata => { :foo => "bar", :bar => "Foobar" } } },
                 { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal("bar", json["metadata"]["foo"])
    assert_equal("Foobar", json["metadata"]["bar"])

    put :update, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json',
                   :collection => { :metadata => { :foo2 => "bar", :bar => "foo" } } },
                 { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal("bar", json["metadata"]["foo2"])
    assert_equal("bar", json["metadata"]["foo"], "Old metadata key was lost while updating")
    assert_equal("foo", json["metadata"]["bar"])

    # Try to update the collection's id and owner
    put :update, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json',
                   :collection => { :id => "9999", :owner_id => "9999" } },
                 { :session_id => sessions(:session1).id }
    assert_not_equal("9999", json["id"])


    # Try to update metadata for a collection belonging to another user
    put :update, { :app_id => clients(:one).id, 
                   :id => collections(:two).id, 
                   :format => 'json',
                   :collection => { :metadata => { :foo2 => "bar", :bar => "foo" } } },
                 { :session_id => sessions(:session1).id }
    assert_response :forbidden
  end
  
  def test_indestructible
    #create indfestructible and try to delete
    post :create, { :app_id => clients(:one).id, :indestructible => "true", :format => 'json'}, 
                  { :session_id => sessions(:session1).id, :client => clients(:one).id }
    assert_response :created
    assert_not_nil assigns["collection"]
    json = JSON.parse(@response.body)
    assert_not_nil json["id"]
    
    delete :delete, { :app_id => clients(:one).id, :id => json["id"], :format => 'json' }, 
                    { :session_id => sessions(:session1).id }
    assert_response :forbidden
    
    #try to create indestructible with an owner
    post :create, { :app_id => clients(:one).id, :indestructible => "true", :format => 'json', :owner => people(:valid_person).id }, 
                  { :session_id => sessions(:session1).id, :client => clients(:one).id }
    assert_response :bad_request
  end
  
  def test_read_only
    get :show, { :app_id => clients(:one).id, :id => collections(:read_only).id, :format => 'json' },
               { :session_id => sessions(:session1).id }
    assert_response :success
    old_item_count = assigns["collection"].items.count
    json = JSON.parse(@response.body)
    
    # Should not be able to add to a read_only collection belonging to other (non-friend)  user
    post :add, { :app_id => clients(:one).id, :id => collections(:read_only).id, :format => 'json', 
                 :title => "The Engine", :content_type => "text/plain", :body => "Lorem ipsum dolor sit amet." },
               { :session_id => sessions(:session3).id }
    assert_response :forbidden
    
    #check that item count didn't change
    get :show, { :app_id => clients(:one).id, :id => collections(:read_only).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(old_item_count, assigns["collection"].items.count)
  end
  
  def test_error_reporting
    post :add, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json', 
                 :file => fixture_file_upload("collections.yml","image/png"), 
                 :full_image_size => '240x300'},
               { :session_id => sessions(:session1).id }
    assert_response :bad_request

    get :show, { :app_id => clients(:one).id, :id => collections(:one).id + "eoscrh", :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :not_found
  end

end
