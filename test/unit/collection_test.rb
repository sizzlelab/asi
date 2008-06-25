require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  fixtures :collections, :people, :text_items, :binary_items, :clients, :connections

  def test_should_create_collection

    old_count = Collection.find(:all).length

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

    assert_equal(Collection.find(:all).length, old_count+1)

    assert_nothing_raised { Collection.find(collection.id) } 
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
  
  def test_permissions
    # Should be able to read, write and delete a collection without an owner
    collection = collections(:one)
    client = collection.client
    person = people(:valid_person)

    assert_nil collection.owner

    assert collection.read?(person, client)
    assert collection.write?(person, client)
    assert collection.delete?(person, client)

    # Should be able to read and write and delete a self-owned collection
    collection = collections(:two)
    client = collection.client
    person = collection.owner

    assert collection.read?(person, client)
    assert collection.write?(person, client)
    assert collection.delete?(person, client)

    # Should be able to read and write but not delete a collection owned by a friend
    collection = collections(:three)
    client = collection.client
    person = collection.owner.contacts[0]

    assert collection.owner.contacts.include?(person)
    assert person.contacts.include?(collection.owner)

    assert collection.read?(person, client)
    assert collection.write?(person, client)
    assert ! collection.delete?(person, client)

    # Should not be able to write in the previous case if the collection is read_only
    collection = collections(:three)
    collection.read_only = true
    client = collection.client
    person = collection.owner.contacts[0]

    assert collection.owner.contacts.include?(person)
    assert person.contacts.include?(collection.owner)

    assert collection.read?(person, client)
    assert ! collection.write?(person, client)
    assert ! collection.delete?(person, client)
    
    # Should not be able to do anything to a collection belonging to another person
    collection = collections(:three)
    client = collection.client
    person = people(:contact)
    
    assert ! collection.owner.contacts.include?(person)
    assert ! person.contacts.include?(collection.owner)

    assert ! collection.read?(person, client)
    assert ! collection.write?(person, client)
    assert ! collection.delete?(person, client)
    
    # Should not be able to do anyting to a collection belonging to another client
    collection = collections(:three)
    client = clients(:one)
    person = people(:contact)
    
    assert_not_equal(collection.owner, client)

    assert ! collection.read?(person, client)
    assert ! collection.write?(person, client)
    assert ! collection.delete?(person, client)
  end

end
