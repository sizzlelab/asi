require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase

  def setup
    @controller = CollectionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_index
    get :index, { :app_id => clients(:one).id}, { :client => clients(:one).id }
    assert_response :success
    assert_not_nil assigns["collections"]

    # Should only return collections relevant to this client
    for collection in assigns["collections"]
      assert_equal(collection.client, clients(:one))
    end
  end

  def test_show
    # Should show a collection belonging to the client
    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :client => clients(:one).id }

    assert_response :success
    assert_not_nil assigns["collection"]

    # Should not show a collection belonging to another client
    get :show, { :app_id => clients(:two).id, :id => collections(:one).id, :format => 'json' }, 
               { :client => clients(:two).id }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should not show a collection belonging to another user
    get :show, { :id => collections(:one).id, :format => 'json' }, 
               { :client => clients(:two).id, :user => people(:contact) }

    assert_response :forbidden
    assert_nil assigns["collection"]

    # Should show a collection belonging to a connection of the user
    get :show, { :app_id => clients(:one).id, :id => collections(:three).id, :format => 'json' }, 
               { :client => collections(:three).client.id, :user => people(:valid_person).id }

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

  end

  def test_create
    # With an owner and a client
    post :create, { :app_id => clients(:one).id, :format => 'json', :owner => people(:valid_person).id }, 
                  { :user => people(:valid_person).id, :client => clients(:one).id }
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
                    { :client => clients(:one).id }
    assert_response :success

    get :show, { :app_id => clients(:one).id, :id => collections(:one).id, :format => 'json' }, 
               { :client => clients(:one).id }
    assert_response :not_found

    # Should not allow POST
    post :delete, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
                  { :client => clients(:one).id }
    assert_response :method_not_allowed

    # TODO: Should allow POST overridden with DELETE
#     @request.set_header "X-HTTP-Method-Override", "DELETE"
#     post :delete, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
#                   { :client => clients(:one).id }
#     assert_response :success
    
#     get :show, { :app_id => clients(:one).id, :id => collections(:two).id, :format => 'json' }, 
#                { :client => clients(:one).id }
#     assert_response :not_found

    # Should not delete a collection belonging to another client
    delete :delete, { :id => collections(:two).id, :format => 'json' }, 
                    { :client => clients(:one).id }
    assert_response :forbidden

    # Should not delete a collection belonging to another user
    delete :delete, { :id => collections(:two).id, :user => people(:valid_person).id, :format => 'json' }, 
                    { :client => clients(:two).id }
    assert_response :forbidden

    # Should not delete a collection belonging to a friend
    delete :delete, { :app_id => clients(:one).id, :id => collections(:three).id, :format => 'json' }, 
                    { :client => collections(:three).client.id, :user => people(:valid_person).id }

    assert people(:valid_person).contacts.include?(collections(:three).owner)
    assert_response :forbidden

  end

end
