require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  
  def setup
    @image_jpg = images(:jpg)
    @image_png = images(:png)
  end
  
  def should_create_image
    image = Image.new
    assert image.exists?
  end

  def test_should_find_image
    id = images(:jpg).id
    assert_nothing_raised { Image.find(id) }
  end

  def test_should_resize_image
    image = @image_jpg
    image.person_id = people(:valid_person).id
    assert image.valid_file?("image/jpeg", "test.jpg")
    assert image.convert("image.jpg")
  end  
   
  def test_should_update_image
    image = images(:jpg)
    data = images(:png).raw_data
    image.person_id = people(:valid_person).id
    assert image.update_attributes(:data => data, :filename => "Foo.bin") 
    assert_equal(image.data, images(:png).data)
  end

  def test_should_destroy_image
    image = images(:jpg)
    image.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Image.find(image.id) }
  end
  
end
