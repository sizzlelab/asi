class Image < ActiveRecord::Base

  usesguid
  
  belongs_to :person

  attr_accessor :full_image_size, :thumbnail_size

  def save_to_db?(options)
    self.content_type = options[:file].content_type
    self.filename = options[:file].original_filename 
    self.data = options[:file].read
    self.full_image_size = options[:full_image_size]
    self.thumbnail_size = options[:thumbnail_size]                  
    if valid_file? and successful_conversion?
      self.save
      return true
    end 
    return false    
  end

  # Return true for a valid, nonempty image file.
  def valid_file?
    
    #The upload should be nonempty.
    if self.filename == nil
      errors.add_to_base("Please enter an image filename")
      return false
    end
    
    #The file should be an image file.
    unless self.content_type =~ /^image/
      errors.add(:content_type, "is not a recognized format")
      return false
    end
    
    #The file shouldn't be bigger than 10 megabytes.
    if raw_data.size > 10.megabytes
      errors.add("Image can't be bigger than 10 megabytes")  
      return false
    end
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
    img   = system("#{'convert'} '#{source_file}' -resize #{full_image_size} '#{full_size_image_file}'")
    thumb = system("#{'convert'} '#{source_file}' -resize #{thumbnail_size} '#{thumbnail_file}'")
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
      :data => data,
      :thumbnail => thumbnail
    }.to_json(*a)
  end

  def data
    return Base64.encode64(super)
  end

  def raw_data
    return Base64.decode64(data)
  end

  def thumbnail
    return Base64.encode64(super)
  end  
  
  def raw_thumbnail
    return Base64.decode64(thumbnail)
  end
end
