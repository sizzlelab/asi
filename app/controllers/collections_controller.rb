class CollectionsController < ApplicationController

  before_filter :verify_client

  verify :method => :post, 
         :only => :create, 
         :render => { :status => :method_not_allowed },
         :add_headers => {'Allow' => 'POST'}

  verify :method => :delete,
         :only => [ :delete ],
         :render => { :status => :method_not_allowed },
         :add_headers => {'Allow' => 'DELETE'}

  verify :method => :put,
         :only => [ :update ],
         :render => { :status => :method_not_allowed },
         :add_headers => {'Allow' => 'PUT'}

  def index
    @collections = Collection.find(:all, :conditions => { :client_id => session["client"] })
    @app_id = params["app_id"]
    @auth_app = session["client"]
  end

  def show
    @collection = Collection.find(params['id'])

    if ! check_authorization(@collection)
      @collection = nil
      render :status => :forbidden
    end
  end

  def create
    @collection = Collection.new

    if params['owner'] and params['owner'] = session['user']
      @collection.owner = Person.find(session['user'])
    end

    @collection.client = Client.find(session['client'])
    @collection.save
  end

  def update
    @collection = Collection.find(params['id'])
    @collection.update_attributes(params[:collection])
  end

  def delete
    @collection = Collection.find(params['id'])
    if ! check_authorization(@collection)
      render :status => :forbidden and return
    end
    @collection.destroy
  end

  private
  def verify_client
    if ! session["client"] or params["app_id"].to_s != session["client"].to_s
      render :status => :forbidden and return
    end
  end

  #TODO Should expose collections to friends
  def check_authorization(collection)
    if @collection.client.id != session["client"] or 
        (@collection.owner and @collection.owner.id != session["user"])
      return false
    end
    return true
  end

end
