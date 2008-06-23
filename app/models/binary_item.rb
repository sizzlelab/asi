class BinaryItem < ActiveRecord::Base

  def to_json(*a)
    {
      :id => id,
      :content_type => content_type,
      :filename => filename,
      :value => data
    }.to_json(*a)
  end

  def data
    return Base64.encode64(super)
  end

  def raw_data
    return Base64.decode64(data)
  end

end
