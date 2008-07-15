module LoggingHelper
  def to_json(*a)
    {
      :method => method,
      :url => path,
      :timestamp => Time.now
    }.merge(a[0]).to_json
  end
end
