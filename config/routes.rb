ActionController::Routing::Routes.draw do |map|
  
  #these are just for browser testing
  map.root :controller => 'people', :action => 'index'  #FROM AUTH can be removed later 
   map.resources :sessions   #FROM AUTH can be removed later
   map.resources :people     #FROM AUTH can be removed later

  map.connect '/appdata/:app_id/@collections', :controller => 'collections', 
                                               :action => 'index', 
                                               :format => 'json', 
                                               :conditions => { :method => :get }

  map.connect '/appdata/:app_id/@collections', :controller => 'collections', 
                                               :action => 'create', 
                                               :format => 'json', 
                                               :conditions => { :method => :post }

  map.connect '/appdata/:app_id/@collections/:id', :controller => 'collections',
                                                   :action => 'show',
                                                   :format => 'json',
                                                   :conditions => { :method => :get }

  map.connect '/appdata/:app_id/@collections/:id', :controller => 'collections',
                                                   :action => 'delete',
                                                   :format => 'json',
                                                   :conditions => { :method => :delete }                          

  map.connect '/appdata/:app_id/@collections/:id', :controller => 'collections',
                                                   :action => 'add',
                                                   :format => 'json',
                                                   :conditions => { :method => :post } 

  map.connect '/people',  :controller => 'people',
                          :action => 'create',
                          :format => 'json',
                          :conditions => { :method => :post}
                          
  map.connect '/people/:user_id', :controller => 'people',
                                  :action => 'show',
                                  :format => 'json',
                                  :conditions => { :method => :get}               
                          
  map.connect '/people/:user_id/@friends', :controller => 'people',
                                           :action => 'get_friends',
                                           :format => 'json',
                                           :conditions => { :method => :get }
                                            
  map.connect '/people/:user_id/@friends', :controller => 'people',
                                           :action => 'add_friend',
                                           :format => 'json',
                                           :conditions => { :method => :post }
                                            
  map.connect '/people/:user_id/@friends/:friend_id', :controller => 'people',
                                                      :action => 'remove_friend',
                                                      :format => 'json',
                                                      :conditions => { :method => :delete }
  
  
  map.connect '/session', :controller => 'sessions',
                          :action => 'destroy',
                          :format => 'json',
                          :conditions => { :method => :delete }                                          
                     
  
  map.connect '/session',  :controller => 'sessions',
                          :action => 'create',
                          :format => 'json',
                          :conditions => { :method => :post}                                            

  map.connect '/', :controller => 'application',
                   :action => 'index',
                   :contiditons => { :method => :get }

  # XXX This route is fake - but without it, functional tests won't run
  map.connect '/:controller/:action'
end
