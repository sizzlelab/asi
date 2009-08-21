module SystemHelper

  def rake(task)
    system "rake #{task} RAILS_ENV=#{ENV['RAILS_ENV']} &"
  end

end
