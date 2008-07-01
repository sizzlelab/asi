class Image < ActiveRecord::Base

  # Image sizes
  FULL_IMAGE_SIZE = '"240x300"'
  THUMBNAIL_SIZE = '"50x64"'

  # Return true for a valid, nonempty image file.
  def valid_file?
    # The upload should be nonempty.
    # if filename.size.zero?
    #       errors.add_to_base("Please enter an image filename")
    #       return false
    #     end
    #     unless self.content_type =~ /^image/
    #       errors.add(:content_type, "is not a recognized format")
    #       return false
    #     end
    #     if raw_data.size > 1.megabytes
    #       errors.add(:image, "can't be bigger than 10 megabytes")
    #       return false    
    #     end
    return true
  end
  
  # Returns true if conversion of image is successful.
  def successful_conversion?
    source_file = File.join("#{RAILS_ROOT}/test/fixtures/", "temp_#{filename}")
    full_size_image_file = File.join("#{RAILS_ROOT}/test/fixtures/", "full_#{filename}")
    thumbnail_file = File.join("#{RAILS_ROOT}/test/fixtures/", "thumb_#{filename}")
    # Write the source file to directory.
    f = File.new(source_file, "wb")
    f.write(self.raw_data)
    f.close
    # Then convert the source file to a full size image and a thumbnail.
    img   = system("#{'convert'} '#{source_file}' -resize #{FULL_IMAGE_SIZE} '#{full_size_image_file}'")
    thumb = system("#{'convert'} '#{source_file}' -resize #{THUMBNAIL_SIZE} '#{thumbnail_file}'")
    File.delete(source_file) if File.exists?(source_file)
    # Both conversions must succeed, else it's an error.
    unless img and thumb
      errors.add_to_base("File upload failed.  Try a different image?")
      return false
    end
    # Write new images to database and then delete image files.
    self.data = File.open(full_size_image_file,'rb').read
    File.delete(full_size_image_file) if File.exists?(full_size_image_file)
    self.thumbnail = File.open(thumbnail_file,'rb').read
    File.delete(thumbnail_file) if File.exists?(thumbnail_file)
    return true
  end

  def to_json(*a)
    {
      :id => id,
      :filename => filename,
      :data => data
    }.to_json(*a)
  end

  def data
    return Base64.encode64(super)
  end

  def raw_data
    return Base64.decode64(data)
  end

end
