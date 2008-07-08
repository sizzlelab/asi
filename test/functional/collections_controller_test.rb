require 'test_helper'

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

    # Should only return collections relevant to this client
    for collection in assigns["collections"]
      assert_equal(collection.client, clients(:one))
    end

    # Should not crash on a nonexistent client
    get :index, { :app_id => -1, :format => 'json' }
    assert_response 403
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

    # Should not show a collection belonging to another client
    get :show, { :app_id => clients(:two).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session2).id }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should not show a collection belonging to another user
    get :show, { :id => collections(:one).id, :format => 'json' }, 
               { :client => clients(:two).id, :user => people(:contact) }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should show a collection belonging to a connection of the user
    get :show, { :app_id => clients(:one).id, :id => collections(:three).id, :format => 'json' }, 
               { :client => collections(:three).client.id, :user => people(:valid_person).id, :session_id => sessions(:session1).id }

    assert people(:valid_person).contacts.include?(collections(:three).owner)
    assert_response :success
    assert_not_nil assigns["collection"]

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
    assert_response :success
    assert_not_nil assigns["collection"]
    assert_equal(assigns["collection"].owner, people(:valid_person))
    assert_equal(assigns["collection"].client, clients(:one))

    # With only a client
    post :create, { :app_id => clients(:one).id, :format => 'json'}, 
                  { :client => clients(:one).id }
    assert_response :success
    assert_not_nil assigns["collection"]
    assert_nil assigns["collection"].owner
    assert_equal(assigns["collection"].client, clients(:one))

    # With only an owner
    post :create, { :format => 'json' }, 
                  { :user => people(:valid_person).id }
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

    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :not_found

    # Should not allow POST
    post :delete, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
                  { :session_id => sessions(:session1).id }
    assert_response :method_not_allowed

    # TODO: Should allow POST overridden with DELETE
#     @request.set_header "X-HTTP-Method-Override", "DELETE"
#     post :delete, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json', :_method => "DELETE" }, 
#                   { :client => clients(:one).id }
#     assert_response :success
    
#     get :show, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
#                { :client => clients(:one).id }
#     assert_response :not_found

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

    # Should be able to add to a collection belonging to the client
    post :add, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json', 
                 :title => "The Engine", :content_type => "text/plain", :body => "Lorem ipsum dolor sit amet." },
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(old_item_count+1, assigns["collection"].items.count)
  end

  def test_add_image
    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :success
    old_item_count = assigns["collection"].items.count

    # Should be able to add to a collection belonging to the client
    post :add, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json', 
                 :file => fixture_file_upload("Bison_skull_pile.png","image/png") },
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(old_item_count+1, assigns["collection"].items.count)
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
    assert_equal("bar", json["metadata"]["foo"])
    assert_equal("foo", json["metadata"]["bar"])
  end
end
