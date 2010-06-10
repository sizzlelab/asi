require 'find'

class ApiController < ApplicationController

  skip_before_filter :log

  def api
    if  ENV['RAILS_ENV'] == "development" && api_changed?
      system("script/rapidoc/generate")
    end
    render :action => request.path[1..-1].gsub(/\/$/, "").gsub("doc/", ""), :layout => "doc"
  end

  private

  def api_changed?
    last_modified("app/controllers") > last_modified("app/views/api")
  end

  def last_modified(dir)
    File.mtime(Dir["#{dir}**/*"].map { |p| [ p, File.mtime(p) ] }.max { |a,b| a[1] <=> b[1] }[0]) rescue nil
  end

end
