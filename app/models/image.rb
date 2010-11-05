# == Schema Information
#
# Table name: images
#
#  id          :string(255)     default(""), not null, primary key
#  filename    :string(255)
#  data        :binary(21474836
#  created_at  :datetime
#  updated_at  :datetime
#  person_id   :integer(4)
#  small_thumb :binary
#  large_thumb :binary
#

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

  DEFAULT_AVATAR_IMAGES = {
    "cos" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
    },
    "ossi" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "cos_avatar_80_80.jpg",
      "small_thumb" => "cos_avatar_50_50.jpg"
    },
    "kassi" => {
      "full" => "kassi_avatar.png",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
    }
  }

  validates_presence_of :person_id
  validate :valid_file

  attr_accessor :file

  before_create :file_to_db


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

  # return true if all the image data fields are populated
  def valid_image_data?

    #There should be image data.
    unless self.data?
      errors.add_to_base("No image data.")
      return false
    end

    #There should be large thumbnail data.
    unless self.large_thumb?
      errors.add_to_base("No large thumbnail image data.")
      return false
    end

    #There should be small thumbnail data.
    unless self.small_thumb?
      errors.add_to_base("No small thumbnail image data.")
      return false
    end

    return true
  end

  private

  def file_to_db
    self.data = self.file.read
    convert(self.file.original_filename)
  end

  # Return true for a valid, nonempty image file.
  def valid_file

    filename = self.file.original_filename
    content_type = self.file.content_type

    #The upload should be nonempty.
    if filename == nil
      errors.add_to_base("Please enter an image filename")
      return false
    end

    #The upload should have file suffix.
    unless filename =~ /\.(jpg)|(jpeg)|(png)|(gif)$/i
      errors.add_to_base("Please use image file with a filename suffix")
      return false
    end

    #The file should be an image file.
    unless content_type =~ /^image/
      errors.add(:content_type, "is not a recognized format")
      return false
    end
    return true
  end

  # Returns true if conversion of image is successful.
  def convert(filename)

    uuid = UUID.timestamp_create().to_s22
    convert = 'convert'

    source_file          = File.join(RAILS_ROOT, DIRECTORY, "#{uuid}_#{filename}")
    full_size_image_file = File.join(RAILS_ROOT, DIRECTORY, "#{uuid}_full_image.jpg")
    large_thumbnail_file = File.join(RAILS_ROOT, DIRECTORY, "#{uuid}_large_thumb_image.jpg")
    small_thumbnail_file = File.join(RAILS_ROOT, DIRECTORY, "#{uuid}_small_thumb_image.jpg")

    # Write the source file to directory.
    f = File.new(source_file, "wb")
    f.write(self.raw_data)
    f.close

    # Then resize the source file to the size defined by full_image_size parameter
    # and convert it to .jpg file. Resize uses ImageMagick directly from command line.
    # System calls return true on success and the empty string on failure.
    system("#{convert} '#{source_file}' -resize #{FULL_IMAGE_SIZE} '#{full_size_image_file}'")
    system("#{convert} '#{source_file}' -resize #{LARGE_THUMB_SIZE} '#{large_thumbnail_file}'")

    # Make a thumbnail using RMagick. Thumbnail is created by cutting as big as possible
    # square-shaped piece from the center of the image and then resizing it to 50x50px.
    small_thumb = Magick::Image.read(source_file).first
    small_thumb.crop_resized!(SMALL_THUMB_WIDTH, SMALL_THUMB_HEIGHT, Magick::NorthGravity)
    small_thumb.write(small_thumbnail_file)

    # All conversions must succeed, else it's an error, probably because image file
    # is somehow corrupted.
    unless File.exists?(full_size_image_file) and File.exists?(large_thumbnail_file) and File.exists?(small_thumbnail_file)
      errors.add_to_base("File upload failed. Image file is probably corrupted.")
      return false
    end

    # Write new images to database and then delete image files.
    self.data = File.open(full_size_image_file,'rb').read
    File.delete(full_size_image_file)
    self.large_thumb = File.open(large_thumbnail_file,'rb').read
    File.delete(large_thumbnail_file)
    self.small_thumb = File.open(small_thumbnail_file,'rb').read
    File.delete(small_thumbnail_file)

    # Delete source file if it exists.
    File.delete(source_file)

    return true
  end
end
