class SearchController < ApplicationController

  before_filter :ensure_client_login, :search

  def search
    if not params[:query] or params[:query].empty?
      render :status => :bad_request, :json => "No query parameter provided.".to_json and return
    end
  end

end
