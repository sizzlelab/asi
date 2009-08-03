class SearchController < ApplicationController

  before_filter :ensure_client_login

  def search
    if not params[:search] or params[:search].empty?
      render_json :status => :bad_request, :messages => "No query parameter provided." and return
    end
    query = (params['search'] || "").strip
    result = ThinkingSphinx::Search.search("*#{query}*")
    result.collect! do |r|
      { :type => r.class.name, :result => r.to_hash(@user, @client) }
    end
    render_json :entry => result
  end

end
