require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  fixtures :collections, :people, :text_items, :binary_items, :clients

  def test_should_create_collection
    collection = Collection.new
    collection.read_only = true
 
    collection.owner = people(:valid_person)
    assert collection.save

    collection.client = clients(:one)
    assert collection.save

    collection.items << text_items(:one)
    collection.items << binary_items(:jpg)
    assert collection.save

    assert(collection.items.count, 2)
    assert(collection.text_items.count, 1)
    assert(collection.binary_items.count, 1)
  end

  def test_should_find_collection
    id = collections(:one).id
    assert_nothing_raised { 
      collection = Collection.find(id) 
      assert_not_nil(collection.client)
      assert_equal(collection.client, clients(:one)) 
   }
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
