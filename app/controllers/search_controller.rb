class SearchController < ApplicationController

  before_filter :ensure_client_login

=begin rapidoc
access:: Client login
return_code:: 200
json:: { "pagination": {
    "size": 42,
    "per_page": 4,
    "page": 1
  },
  "entry": [

] }
param:: search - The search term.
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
    result.collect! { |r| { :type => r.type, :result => r.to_hash(@user, @client) } }
    render_json :entry => result, :size => result.count_available
  end

end
