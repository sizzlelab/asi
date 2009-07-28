class SearchController < ApplicationController

  before_filter :ensure_client_login, :search

  def search
    if not params[:query] or params[:query].empty?
      render_json :status => :bad_request, :messages => "No query parameter provided." and return
    end
  end

end
