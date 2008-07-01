require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  
  def setup
    @image_jpg = images(:jpg)
    @image_png = images(:png)
  end
  
  def should_create_image
    image = Image.new
  end

  def test_should_find_image
    id = images(:jpg).id
    assert_nothing_raised { Image.find(id) }
  end

  def test_should_resize_image
    image = @image_jpg
    assert image.valid_file?
    assert image.successful_conversion?
    f = File.new(thumbnail_file = File.join("#{RAILS_ROOT}/test/fixtures/testithumb"), "wb")
    f.write(self.raw_data)
    f.close
  end  
   
  # def test_should_update_image
  #   image = images(:jpg)
  #   data = images(:png).raw_data
  #   assert image.update_attributes(:data => data, :filename => "Foo.bin")
  # 
  #   assert_equal(image.data, images(:png).data)
  # end

  def test_should_destroy_image
    image = images(:jpg)
    image.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Image.find(image.id) }
  end
  
end
