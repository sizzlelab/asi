class SearchController < ApplicationController

  before_filter :ensure_client_login

=begin rapidoc
access:: Client login
return_code:: 200
json:: { "pagination" => {
    "size" => 42,
    "per_page" => 3,
    "page" => 1
  },
  "entry" => [
 { :type => "Person", :result => APIFactory.create_person },
 { :type => "Group", :result => APIFactory.create_group },
 { :type => "Channel", :result => APIFactory.create_channel },

] }
param:: search - The search term. Sensible results for search terms under the length of 2 are not guaranteed. Wildcards are supported; the search is by default a wildcard search from both sides.
param:: per_page - How many results to show per page.
param:: page - Which page to show. Indexing starts at 1.

description:: Performs a fulltext search spanning people, channels, messages and groups. Results are sorted by relevance.

=end
  def search
    if not params[:search] or params[:search].empty?
      render_json :status => :bad_request, :messages => "No query parameter provided." and return
    end
    query = (params['search'] || "").strip
    result = ThinkingSphinx::Search.search("*#{query}*")
    result.filter_paginate!(params[:per_page], params[:page]) { |r| r.show?(@user, @client) }
    result.collect! { |r| { :type => r.typestr, :result => r.to_hash(@user, @client) } }
    render_json :entry => result, :size => result.count_available
  end

end
