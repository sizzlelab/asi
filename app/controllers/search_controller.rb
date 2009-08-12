class SearchController < ApplicationController

  before_filter :ensure_client_login

=begin rapidoc
access:: Client login
return_code:: 200
json:: { "entry": [
 { "type": "Channel",
   "result": { See <%= link_to_api("/channels/channel_id") %> }
 },
 { "type":"Message",
   "result": { See <%= link_to_api("/channels/channel_id>/@messages/msg_id") %> }
 },
 { "type":"Group",
   "result": { See <%= link_to_api("/groups/group_id/@public") %> }
 },
 { "type":"Person",
   "result":{ See <%= link_to_api("/people/user_id/@self") %> }
 }
] }
param:: search - The search term.

description:: Performs a fulltext search spanning people, channels, messages and groups.

=end
  def search
    if not params[:search] or params[:search].empty?
      render_json :status => :bad_request, :messages => "No query parameter provided." and return
    end
    query = (params['search'] || "").strip
    result = ThinkingSphinx::Search.search("*#{query}*")
    result.reject! { |r| ! r.show?(@user, @client) }
    result.collect! { |r| { :type => r.type, :result => r.to_hash(@user, @client) } }
    render_json :entry => result
  end

end
