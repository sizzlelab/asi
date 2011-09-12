
Asi::Application.routes.draw do
  # admin
  namespace :admin do
    resources :feedbacks do
      member do
        put :handle
      end
    end
  end
  
  # coureui
  namespace :coreui do
    match '/', :to => 'profile#index', :via => :get
    resources :profile do
      collection do
        get :question
        post :create
        post :new
        post :link
        get :link
      end
    end
    resources :privacy
  end

  # Application-specific client data
  match '/appdata', :to => 'appdata#index', :via => :get, :format => 'json'
  match '/appdata/:user_id/@self/:app_id', :to => 'client_data#show', :via => :get, :format => 'json'
  match '/appdata/:user_id/@self/:app_id', :to => 'client_data#update', :via => :put, :format => 'json'

  match '/appdata/:app_id/@collections', :to => 'collections#index', :via => :get, :format => 'json'
  match '/appdata/:app_id/@collections', :to => 'collections#create', :via => :post, :format => 'json'

  match '/appdata/:app_id/@collections/:id', :to => 'collections#show', :via => :get, :format => 'json'
  match '/appdata/:app_id/@collections/:id', :to => 'collections#delete', :via => :delete, :format => 'json'
  match '/appdata/:app_id/@collections/:id', :to => 'collections#add', :via => :post, :format => 'json'
  match '/appdata/:app_id/@collections/:id', :to => 'collections#update', :via => :put, :format => 'json'

  match '/appdata/:app_id/@collections/:id/@items/:item_id', :to => 'collections#delete_item', :via => :delete, :format => 'json'

  #shortcut for the longer url above (without collection id)
  match '/appdata/:app_id/@collection_items/:item_id', :to => 'collections#delete_item', :via => :delete, :format => 'json'



  # People
  match '/people/:user_id/@self', :to => 'people#show', :via => :get, :format => 'json'
  match '/people/:user_id/@self', :to => 'people#update', :via => :put, :format => 'json'
  match '/people/:user_id/@self', :to => 'people#delete', :via => :delete, :format => 'json'

  match '/people/:user_id/@avatar', :to => 'avatars#show', :via => :get, :format => 'jpg'
  match '/people/:user_id/@avatar', :to => 'avatars#update', :via => :post, :format => 'html'
  match '/people/:user_id/@avatar', :to => 'avatars#delete', :via => :delete, :format => 'json'

  match '/people/:user_id/@avatar/large_thumbnail', :to => 'avatars#show_large_thumbnail', :via => :get, :format => 'jpg'
  match '/people/:user_id/@avatar/small_thumbnail', :to => 'avatars#show_small_thumbnail', :via => :get, :format => 'jpg'

  match '/people', :to => 'people#index', :via => :get, :format => 'json'
  match '/people', :to => 'people#create', :via => :post, :format => 'json'

  match '/people/:user_id/@friends', :to => 'people#get_friends', :via => :get, :format => 'json'
  match '/people/:user_id/@friends', :to => 'people#add_friend', :via => :post, :format => 'json'

  match '/people/:user_id/@pending_friend_requests', :to => 'people#pending_friend_requests', :via => :get, :format => 'json'

  match '/people/:user_id/@pending_friend_requests/:friend_id', :to => 'people#reject_friend_request', :via => :delete, :format => 'json'

  match '/people/:user_id/@friends/:friend_id', :to => 'people#remove_friend', :via => :delete, :format => 'json'

  match '/people/:user_id/@location', :to => 'locations#get', :via => :get, :format => 'json'
  match '/people/:user_id/@location', :to => 'locations#update', :via => :put, :format => 'json'
  match '/people/:user_id/@location', :to => 'locations#update', :via => :post, :format => 'json'
  match '/people/:user_id/@location', :to => 'locations#destroy', :via => :delete, :format => 'json'

  match '/people/:user_id/@location/@location_security_token', :to => 'locations#fetch_location_security_token', :via => :get, :format => 'json'

  match '/people/recover_password', :to => 'people#recover_password', :via => :post, :format => 'json'
  
  match '/people/availability', :to => 'people#availability', :via => :get, :format => 'json'

  match '/people/reset_password', :to => 'people#reset_password', :via => :get, :format => 'html'

  match '/people/change_password', :to => 'people#change_password', :via => :post, :format => 'html'

  match '/people/:user_id/@groups', :to => 'groups#get_groups_of_person', :via => :get, :format => 'json'
  match '/people/:user_id/@groups', :to => 'groups#add_member', :via => :post, :format => 'json'

  match '/people/:user_id/@groups/@invites', :to => 'groups#get_invites', :via => :get, :format => 'json'

  match '/people/:user_id/@groups/:group_id', :to => 'groups#show_membership', :via => :get, :format => 'json'
  match '/people/:user_id/@groups/:group_id', :to => 'groups#update_membership_status', :via => :put, :format => 'json'
  match '/people/:user_id/@groups/:group_id', :to => 'groups#remove_person_from_group', :via => :delete, :format => 'json'

  match '/people/:user_id/@groups', :to => 'groups#get_groups_of_person', :via => :get, :format => 'json'
  match '/people/:user_id/@groups', :to => 'groups#add_member', :via => :post, :format => 'json'

  # Groups
  match '/groups', :to => 'groups#create', :via => :post, :format => 'json'

  match '/groups/@public', :to => 'groups#public_groups', :via => :get, :format => 'json'

  # Deprecated
  match '/groups/:group_id', :to => 'groups#show', :via => :get, :format => 'json'
  match '/groups/:group_id', :to => 'groups#update', :via => :put, :format => 'json'

  match '/groups/:group_id/@members', :to => 'groups#get_members', :via => :get, :format => 'json'

  # New version
  match '/groups/@public/:group_id', :to => 'groups#show', :via => :get, :format => 'json'
  match '/groups/@public/:group_id', :to => 'groups#update', :via => :put, :format => 'json'

  match '/groups/@public/:group_id/@members', :to => 'groups#get_members', :via => :get, :format => 'json'

  # Location shortcut
  match '/groups/@public/:group_id/@pending', :to => 'groups#get_pending_members', :via => :get, :format => 'json'
  
  match '/location/single_update', :to => 'locations#update', :via => :post, :format => 'json'


  # Rules
  # Define ways to access the enable and disable from the view with the put method
  match '/coreui/privacy/:user_id/rules/:rule_id/enable',  :to => 'rules#enable', :via => :put
  match '/coreui/privacy/:user_id/rules/:rule_id/disable',  :to => 'rules#disable', :via => :put

  # Rails will create the default routes like http://guides.rubyonrails.org/routing.html 3.2 CRUD, Verbs, and Actions
  resources :rules, :path_prefix => '/coreui/privacy/:user_id'

  # Session
  match '/session', :to => 'sessions#show', :via => :get, :format => 'json'
  match '/session', :to => 'sessions#destroy', :via => :delete, :format => 'json'
  match '/session', :to => 'sessions#create', :via => :post, :format => 'json'

  # Enable logging out from coreui, using link_to (GET).
  match '/coreui/logout', :to => 'sessions#destroy', :via => :get
  # Clear location
  match '/location/:user_id/clear', :to => 'locations#destroy', :via => :get

  # Search
  match '/search', :to => 'search#search', :via => :get, :format => 'json'


  # Channels
  match '/channels', :to => 'channels#index', :via => :get, :format => 'json'
  match '/channels', :to => 'channels#create', :via => :post, :format => 'json'

  match '/channels/:channel_id/', :to => 'channels#show', :via => :get, :format => 'json'
  match '/channels/:channel_id/', :to => 'channels#edit', :via => :put, :format => 'json'
  match '/channels/:channel_id/', :to => 'channels#delete', :via => :delete, :format => 'json'

  match '/channels/:channel_id/@subscriptions/', :to => 'channels#list_subscriptions', :via => :get, :format => 'json'
  match '/channels/:channel_id/@subscriptions/', :to => 'channels#subscribe', :via => :post, :format => 'json'
  match '/channels/:channel_id/@subscriptions/', :to => 'channels#unsubscribe', :via => :delete, :format => 'json'

  match '/channels/:channel_id/@messages', :to => 'messages#index', :via => :get, :format => 'json'
  match '/channels/:channel_id/@messages', :to => 'messages#create', :via => :post, :format => 'json'

  match '/channels/:channel_id/@messages/:msg_id', :to => 'messages#show', :via => :get, :format => 'json'
  match '/channels/:channel_id/@messages/:msg_id', :to => 'messages#delete', :via => :delete, :format => 'json'

  match '/channels/:channel_id/@messages/:msg_id/@replies', :to => 'messages#replies', :via => :get, :format => 'json'


  # BinObjects
  match '/binobjects', :to => 'bin_objects#index', :via => :get, :format => 'json'
  match '/binobjects', :to => 'bin_objects#create', :via => :post, :format => 'json'

  match '/binobjects/:binobject_id/', :to => 'bin_objects#show_data', :via => :get
  match '/binobjects/:binobject_id/', :to => 'bin_objects#edit', :via => :put
  match '/binobjects/:binobject_id/', :to => 'bin_objects#delete', :via => :delete

  match '/binobjects/:binobject_id/@metadata/', :to => 'bin_objects#show', :via => :get, :format => 'json'


  # SMS resource
  match '/sms', :to => 'sms#index', :via => :get, :format => 'json'
  match '/sms', :to => 'sms#smssend', :via => :post, :format => 'json'

  match '/sms/mark', :to => 'sms#smsmark', :via => :put, :format => 'json'


  # Others
  match '/confirmation', :to => 'confirmations#confirm_email'

  match 'confirmation/request_new_confirm_email', :to => 'confirmations#request_new_confirm_email', :format => 'html'

  # Documentation
  match '/doc', :to => 'application#index'
  match '/doc/tutorial', :to => 'application#doc', :format => 'html'
  match '/doc/*route', :to => 'api#api', :format => :html, :via => :get
  match '/test', :to => 'application#test', :action => 'test'

  match '/system/:action', :to => 'system'

  root :to => 'application#index', :via => :get
  match '/:controller/:action/:id', :format => 'json'
  match '/:controller/:action/:id'
  match '/:controller/:action'
  
end
