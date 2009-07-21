require 'rubygems'
require 'RMagick'

class Image < ActiveRecord::Base

  usesguid

  belongs_to :person

  FULL_IMAGE_SIZE = '"600x800>"'
  LARGE_THUMB_SIZE = '"200x350>"'
  SMALL_THUMB_WIDTH = 50
  SMALL_THUMB_HEIGHT = 50
  DIRECTORY = "tmp/images"

  validates_presence_of :person_id

  def save_to_db?(options, person)
    self.data = options[:file].read
    self.person_id = person.id
    if valid_file?(options[:file].content_type, options[:file].original_filename) and convert(options[:file].original_filename)
      self.save
      return true
    end
    return false
  end

  # Return true for a valid, nonempty image file.
  def valid_file?(content_type, filename)

    #The upload should be nonempty.
    if filename == nil
      errors.add_to_base("Please enter an image filename")
      return false
    end

    #The upload should have file suffix
    unless filename =~ /\.(jpg)|(jpeg)|(png)|(gif)$/i
      errors.add_to_base("Please use image file with a filename suffix")
      return false
    end

    #The file should be an image file.
    unless content_type =~ /^image/
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
  def convert(filename)

    uuid = UUID.timestamp_create().to_s22

    source_file = File.join("#{RAILS_ROOT}/#{DIRECTORY}", "#{uuid}_#{filename}")
    full_size_image_file = File.join("#{RAILS_ROOT}/#{DIRECTORY}", "#{uuid}_full_image.jpg")
    large_thumbnail_file = File.join("#{RAILS_ROOT}/#{DIRECTORY}", "#{uuid}_large_thumb_image.jpg")
    small_thumbnail_file = File.join("#{RAILS_ROOT}/#{DIRECTORY}", "#{uuid}_small_thumb_image.jpg")

    # Write the source file to directory.
    f = File.new(source_file, "wb")
    f.write(self.raw_data)
    f.close

    # Then resize the source file to the size defined by full_image_size parameter
    # and convert it to .jpg file. Resize uses ImageMagick directly from command line.
    img = system("#{'convert'} '#{source_file}' -resize #{FULL_IMAGE_SIZE} '#{full_size_image_file}' > #{RAILS_ROOT}/log/convert.log")
    large_thumb = system("#{'convert'} '#{source_file}' -resize #{LARGE_THUMB_SIZE} '#{large_thumbnail_file}' > #{RAILS_ROOT}/log/convert.log")

    # If new file exists, it means that the original file is a valid image file. If so,
    # make a thumbnail using RMagick. Thumbnail is created by cutting as big as possible
    # square-shaped piece from the center of the image and then resizing it to 50x50px.
    if img
      small_thumb = Magick::Image.read(source_file).first
      small_thumb.crop_resized!(SMALL_THUMB_WIDTH, SMALL_THUMB_HEIGHT, Magick::NorthGravity)
      small_thumb.write(small_thumbnail_file)
    end

    # Delete source file if it exists.
    File.delete(source_file) if File.exists?(source_file)

    # Both conversions must succeed, else it's an error, probably because image file
    # is somehow corrupted.
    unless img and large_thumb and small_thumb
      errors.add_to_base("File upload failed. Image file is probably corrupted.")
      return false
    end

    # Write new images to database and then delete image files.
    self.data = File.open(full_size_image_file,'rb').read
    File.delete(full_size_image_file) if File.exists?(full_size_image_file)
    self.large_thumb = File.open(large_thumbnail_file,'rb').read
    File.delete(large_thumbnail_file) if File.exists?(large_thumbnail_file)
    self.small_thumb = File.open(small_thumbnail_file,'rb').read
    File.delete(small_thumbnail_file) if File.exists?(small_thumbnail_file)
    return true
  end

  def to_json(*a)
    {
      :id => id,
      :filename => filename,
      :data => data,
      :small_thumb => small_thumb,
      :large_thumb => large_thumb
    }.to_json(*a)
  end

  def data
    return Base64.encode64(super)
  end

  def raw_data
    return Base64.decode64(data)
  end

  def small_thumb
    return Base64.encode64(super)
  end

  def raw_small_thumb
    return Base64.decode64(small_thumb)
  end

  def large_thumb
    return Base64.encode64(super)
  end

  def raw_large_thumb
    return Base64.decode64(large_thumb)
  end

end
