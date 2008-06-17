require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  fixtures :collections

  def test_should_create_collection
    collection = Collection.new
    collection.read_only = true
    assert ! collection.save
  end

  def test_should_find_collection
    id = collections(:one).id
    assert_nothing_raised { Collection.find(id) }
  end

  def test_should_update_collection
    collection = collections(:one)
    assert collection.update_attributes(:read_only => false)
  end

  def test_should_destroy_collection
    collection = collections(:one)
    collection.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Collection.find(collection.id) }
  end

end
