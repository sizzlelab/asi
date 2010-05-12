module COSRoutes

  def documentation(route)
    connect "doc" + route, :controller => 'api',
                           :format => 'html',
                           :action => 'api'
    connect "api" + route, :controller => 'api',
                           :format => "html",
                           :action => 'api'
  end

  def resource(route, options)
    documentation route.gsub(":", "")
    options.except(:controller, :format_get, :format_put, :format_post).each do |method, action|
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

  map.namespace :admin do |admin|
    admin.resources :feedbacks, :member => { :handle => :put }
  end

  map.namespace :coreui do |coreui|
    coreui.root :controller => 'profile',
                :action => 'index',
                :conditions => { :method => :get }
    coreui.resources :profile
    coreui.resources :privacy
  end

  # Application-specific client data
  map.resource '/appdata', :controller => 'appdata',
                           :get => 'index'

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

  #shortcut for the longer url above (without collection id)
  map.resource '/appdata/:app_id/@collection_items/:item_id', :controller => 'collections',
                                                   # :get => 'show_item',
                                                    :delete => 'delete_item'

  # Role management (Person-client-connection)

  # map.resource '/appdata/:app_id/@people', :controller => 'client', :get => 'index'

  # map.resource '/appdata/:app_id/@people/:roles', :controller => 'client', :get => 'index'

  # map.resource '/people/:user_id/@apps', :controller => 'client', :get => 'index_services',
  #                                                                 :post => 'create'

  # map.resource '/people/:user_id/@apps/:app_id/@role', :controller => 'client', :get => 'show',
  #                                                                               :delete => 'delete',
  #                                                                               :post => 'create',
  #                                                                               :put => 'update'

  # People

  map.resource '/people/:user_id/@self', :controller => 'people',
                                         :get => 'show',
                                         :put => 'update',
                                         :delete => 'delete'

  map.resource '/people/:user_id/@avatar', :controller => 'avatars',
                                           :get => 'show',
                                           :post => 'update',
                                           :delete => 'delete',
                                           :format_get => 'jpg',
                                           :format_post => 'html'


  map.resource '/people/:user_id/@avatar/large_thumbnail', :controller => 'avatars',
                                                           :get => 'show_large_thumbnail',
                                                           :format_get => 'jpg'

  map.resource '/people/:user_id/@avatar/small_thumbnail', :controller => 'avatars',
                                                           :get => 'show_small_thumbnail',
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
                                             :put => 'update',
                                             :post => 'update'

  map.resource '/people/:user_id/@location/@location_security_token', :controller => 'locations',
                                                                     :get => 'fetch_location_security_token'

  map.resource '/people/recover_password', :controller => 'people',
                                           :post => 'recover_password'

  map.connect '/people/reset_password', :controller => 'people',
                                        :action => 'reset_password', :conditions => { :method => :get }

  map.connect '/people/change_password', :controller => 'people',
                                         :action => 'change_password', :format => 'html', :conditions => { :method => :post }

  map.resource '/people/:user_id/@groups', :controller => 'groups',
                                           :get => 'get_groups_of_person',
                                           :post => 'add_member'

  map.resource '/people/:user_id/@groups/@invites', :controller => 'groups',
                                                    :get => 'get_invites'


  map.resource '/people/:user_id/@groups/:group_id', :controller => 'groups',
                                                     :put => 'update_membership_status',
                                                     :get => 'show_membership',
                                                     :delete => 'remove_person_from_group'

  map.resource '/people/:user_id/@groups', :controller => 'groups',
                                           :get => 'get_groups_of_person',
                                           :post => 'add_member'
  # Groups

  map.resource '/groups', :controller => 'groups',
                          :post => 'create'

  map.resource '/groups/@public', :controller => 'groups',
                                  :get => 'public_groups'

  # Deprecated
  map.resource '/groups/:group_id', :controller => 'groups',
                                    :get => 'show',
                                    :put => 'update'


  map.resource '/groups/:group_id/@members', :controller => 'groups',
                                                     :get => 'get_members'

  # New version
  map.resource '/groups/@public/:group_id', :controller => 'groups',
                                            :get => 'show',
                                            :put => 'update'

  map.resource '/groups/@public/:group_id/@members', :controller => 'groups',
                                             :get => 'get_members'

  # Location shortcut

  map.resource '/groups/@public/:group_id/@pending', :controller => 'groups',
                   :get => 'get_pending_members'
  
  map.resource '/location/single_update', :controller => 'locations',
                                          :post => 'update'


  #Rules

    #Define ways to access the enable and disable from the view with the put method
  map.connect '/coreui/privacy/:user_id/rules/:rule_id/enable',  :controller => 'rules',
                                                         :action => 'enable',
                                                         :method => 'put'

  map.connect '/coreui/privacy/:user_id/rules/:rule_id/disable',  :controller => 'rules',
                                                          :action => 'disable',
                                                          :method => 'put'

    #Rails will create the default routes like http://guides.rubyonrails.org/routing.html 3.2 CRUD, Verbs, and Actions
  map.resources :rules, :path_prefix => '/coreui/privacy/:user_id'

  # Others

  map.resource '/session', :controller => 'sessions',
                           :get => 'show',
                           :delete => 'destroy',
                           :post => 'create'

  map.resource '/search', :controller => 'search',
                          :get => 'search'

  # Channels
  map.resource '/channels', :controller => 'channels',
                            :get => 'index',
                            :post => 'create'

  map.resource '/channels/:channel_id/', :controller => 'channels',
                                         :get => 'show',
                                         :put => 'edit',
                                         :delete => 'delete'

  map.resource '/channels/:channel_id/@subscriptions/', :controller => 'channels',
                                                        :get => 'list_subscriptions',
                                                        :post => 'subscribe',
                                                        :delete => 'unsubscribe'

  map.resource '/channels/:channel_id/@messages', :controller => 'messages',
                                                  :get => 'index',
                                                  :post => 'create'

  map.resource '/channels/:channel_id/@messages/:msg_id', :controller => 'messages',
                                                          :get => 'show',
                                                          :delete => 'delete'

  map.resource '/channels/:channel_id/@messages/:msg_id/@replies', :controller => 'messages',
                                                          :get => 'replies'

  # End channels


  # BinObjects
  map.resource '/binobjects', :controller => 'bin_objects',
                            :get => 'index',
                            :post => 'create'

  map.resource '/binobjects/:binobject_id/', :controller => 'bin_objects',
                                         :get => 'show_data',
                                         :put => 'edit',
                                         :delete => 'delete'

  map.resource '/binobjects/:binobject_id/@metadata/', :controller => 'bin_objects',
                                                        :get => 'show'

  # End BinObjects



  map.confirmation '/confirmation', :controller => 'confirmations', :action => 'confirm_email'

  map.request_new_confirm_email "confirmation/request_new_confirm_email", :controller => 'confirmations', :action => "request_new_confirm_email", :format => "html", :format_get => "html"

  map.documentation '/appdata'

  map.connect "doc/tutorial", :controller => 'application',
                           :format => 'html',
                           :action => 'doc'

 # map.apidoc '/api', :controller => 'api', :get => 'index', :format => "html"
 # map.peopleapi '/api/people', :controller => 'api',:action => 'people' ,:get => 'people', :format => 'html'

  map.connect '/doc', :controller => 'application', :action => 'index'

  map.connect '/test', :controller => 'application', :action => 'test'

  map.connect '/system/:action', :controller => 'system'

  map.root :controller => 'application',
           :action => 'index',
           :conditions => { :method => :get }
  map.connect '/:controller/:action/:id', :format => 'json'
  map.connect '/:controller/:action/:id'
  map.connect '/:controller/:action'

end
