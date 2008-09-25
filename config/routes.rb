module COSRoutes

  def documentation(route)
    connect "doc" + route, :controller => 'application',
                           :format => 'html',
                           :action => 'doc'
  end

  def resource(route, options)
    documentation route.gsub(":", "")
    options.except(:controller, :format_put, :format_post).each do |method, action|
      if method.to_s.eql?("get")
        format = options[:format_get] || 'json'
      elsif method.to_s.eql?("post") || method.to_s.eql?("put")  
        format = options[:format_post] || 'json'
      else
        format = 'json'
      end    
      connect route, :controller => options[:controller],
                     :format => format,
                     :action => action,
                     :conditions => { :method => method }
    end
  end
end

ActionController::Routing::Routes.draw do |map|

  map.extend(COSRoutes)

  map.resource '/appdata/:user_id/@self/:app_id', :controller => 'client_data',
                                                  :get => 'show', 
                                                  :put => 'update'

  map.resource '/appdata/:app_id/@collections', :controller => 'collections',
                                                :get => 'index', 
                                                :post => 'create'

  map.resource '/appdata/:app_id/@collections/:id', :controller => 'collections',
                                                    :get => 'show',
                                                    :delete => 'delete',
                                                    :post => 'add',
                                                    :put => 'update'
                                                    
  map.resource '/appdata/:app_id/@collections/:id/@items/:item_id', :controller => 'collections',
                                                   # :get => 'show_item',
                                                    :delete => 'delete_item'

  map.resource '/people/:user_id/@self', :controller => 'people',
                                         :get => 'show', 
                                         :put => 'update', 
                                         :delete => 'delete'

  map.resource '/people/:user_id/@avatar', :controller => 'people',
                                           :post => 'update_avatar',
                                           :get => 'get_avatar', 
                                           :put => 'update_avatar',
                                           :delete => 'delete_avatar',
                                           :format_get => 'jpg',
                                           :format_post => 'html'
                                           
  map.resource '/people/:user_id/@avatar/large_thumbnail', :controller => 'people',
                                                           :get => 'get_large_thumbnail', 
                                                           :format_get => 'jpg'
                                                                                                                                         
  map.resource '/people/:user_id/@avatar/small_thumbnail', :controller => 'people',
                                                           :get => 'get_small_thumbnail', 
                                                           :format_get => 'jpg'
                                                     
  map.resource '/people', :controller => 'people',
                          :post => 'create',
                          :get => 'index'

  map.resource '/people/:user_id/@friends', :controller => 'people',
                                            :get => 'get_friends',
                                            :post => 'add_friend'

  map.resource '/people/:user_id/@pending_friend_requests', :controller => 'people',
                                                            :get => 'pending_friend_requests'

  map.resource '/people/:user_id/@pending_friend_requests/:friend_id', :controller => 'people',
                                                          :delete => 'reject_friend_request'                                                            
                                                            
                                            
  map.resource '/people/:user_id/@friends/:friend_id', :controller => 'people',
                                                       :delete => 'remove_friend'

  map.resource '/people/:user_id/@location', :controller => 'locations',
                                             :get => 'get',
                                             :put => 'update'

  map.resource '/session', :controller => 'sessions',
                           :get => 'get',
                           :delete => 'destroy',
                           :post => 'create'

  map.documentation '/appdata'

  map.connect '/doc', :controller => 'application', :action => 'index'

  map.connect '/test', :controller => 'application', :action => 'test'

  map.root :controller => 'application',
           :action => 'index',
           :conditions => { :method => :get }

  # XXX This is a fake route for functional tests
  map.connect '/:controller/:action', :format => 'json'
end
