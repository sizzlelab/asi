ActionController::Routing::Routes.draw do |map|

  map.connect '/appdata/:app_id/@collections', :controller => 'collections', 
                                               :action => 'index', 
                                               :format => 'json', 
                                               :conditions => { :method => :get }

  map.connect '/appdata/:app_id/@collections', :controller => 'collections', 
                                               :action => 'create', 
                                               :format => 'json', 
                                               :conditions => { :method => :post }

  map.connect '/session', :controller => 'pseudo_authentication',
                          :action => 'login',
                          :format => 'json',
                          :conditions => { :method => :post }

  map.connect '/session', :controller => 'pseudo_authentication',
                          :action => 'logout',
                          :format => 'json',
                          :conditions => { :method => :delete } 

  # XXX This route is fake - but without it, functional tests won't run
  map.connect '/:controller/:action'
end
