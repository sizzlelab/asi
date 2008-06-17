class CollectionsController < ApplicationController

  def index
    @collections = Collection.find(:all)
  end

  def show
    @collection = Collection.find(params['id'])
  end

  def create
    @collection = Collection.new
    @collection.save
  end

  def update
    @collection = Collection.find(params['id'])
    @collection.update_attributes(params[:collection])
  end

  def delete
    @collection = Collection.find(params['id'])
    @collection.destroy
  end

end
