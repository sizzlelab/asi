# == Schema Information
#
# Table name: text_items
#
#  id         :string(255)     default(""), not null, primary key
#  text       :text
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class TextItemTest < ActiveSupport::TestCase
  fixtures :text_items

  def should_create_text_item
    text_item = TextItems.new
  end

  def test_should_find_text_item
    id = text_items(:one).id
    assert_nothing_raised { TextItem.find(id) }
  end

  def test_should_update_text_item
    text_item = text_items(:one)
    assert text_item.update_attributes(:text => "To be or not to be?")
  end

  def test_should_destroy_text_item
    text_item = text_items(:one)
    text_item.destroy
    assert_raise(ActiveRecord::RecordNotFound) { TextItem.find(text_item.id) }
  end

end
