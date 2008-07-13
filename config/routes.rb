module COSRoutes
  def resource(route, options)
    options.except(:controller).each do |method, action|
      connect route, :controller => options[:controller],
                     :format => 'json',
                     :action => action,
                     :conditions => { :method => method }
    end
  end
end


ActionController::Routing::Routes.draw do |map|

  map.extend(COSRoutes)

  map.connect '/appdata/user_id/@self/app_id', :controller => 'client_data',
                                               :action => 'show',
                                               :format => 'html',
                                               :conditions => { :method => :get }

  map.resource '/appdata/:user_id/@self/:app_id', :controller => 'client_data',
                                                  :get => 'show', 
                                                  :put => 'update'

  map.connect '/appdata/app_id/@collections', :controller => 'collections',
                                              :action => 'index',
                                              :format => 'html',
                                              :conditions => { :method => :get }

  map.resource '/appdata/:app_id/@collections', :controller => 'collections',
                                                :get => 'index', 
                                                :post => 'create'


  map.connect '/appdata/app_id/@collections/id', :controller => 'collections',
                                                 :action => 'show',
                                                 :format => 'html',
                                                 :conditions => { :method => :get }
  
  map.resource '/appdata/:app_id/@collections/:id', :controller => 'collections',
                                                    :get => 'show',
                                                    :delete => 'delete',
                                                    :post => 'add'

  map.connect '/appdata', :controller => 'client_data',
                          :action => 'index',
                          :format => 'html',
                          :conditions => { :method => :get }

  map.connect '/people/user_id/@self', :controller => 'people',
                                       :action => 'user_id_@self',                                 
                                       :format => 'html',
                                       :conditions => { :method => :get }

  
  map.resource '/people/:user_id/@self', :controller => 'people',
                                         :get => 'show', 
                                         :put => 'update', 
                                         :delete => 'delete'

  map.resource '/people', :controller => 'people',
                          :post => 'create'

  map.connect '/people/user_id/@friends', :controller => 'people',
                                           :action => 'user_id_@friends',
                                           :format => 'html',
                                           :conditions => { :method => :get }                          

  map.resource '/people/:user_id/@friends', :controller => 'people',
                                            :get => 'get_friends',
                                            :post => 'add_friend'
                                            
  map.connect '/people/:user_id/@friends/:friend_id', :controller => 'people',
                                                      :action => 'user_id_@friends_friend_id',
                                                      :format => 'html',
                                                      :conditions => { :method => :get }
                                                      
  map.resource '/people/:user_id/@friends/:friend_id', :controller => 'people',
                                                       :delete => 'remove_friend'


  map.connect '/people/user_id/@location', :controller => 'locations',
                                            :action => 'index',
                                            :format => 'html',
                                            :conditions => { :method => :get }                                                      

  map.resource '/people/:user_id/@location', :controller => 'locations',
                                             :get => 'get',
                                             :put => 'update'

  map.resource '/session', :controller => 'sessions',
                           :delete => 'destroy',
                           :post => 'create'

  map.connect '/session', :controller => 'sessions',
                          :action => 'index',
                          :format => 'html',
                          :conditions => { :method => :get }                                            

  map.root :controller => 'application',
           :action => 'index',
           :contiditons => { :method => :get }

  # XXX This route is fake - but without it, functional tests won't run
  map.connect '/:controller/:action'
end
