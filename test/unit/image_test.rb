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

  def test_should_destroy_image
    image = images(:jpg)
    image.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Image.find(image.id) }
  end

end
