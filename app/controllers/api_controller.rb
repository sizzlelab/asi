require 'find'

class ApiController < ApplicationController

  skip_before_filter :log

  def api
    if  Rails.env.development? && api_changed?
      system("script/rapidoc/generate")
    end
    render :template => "api/#{request.path[1..-1].gsub(/\/$/, "").gsub("doc/", "")}", :layout => "doc"
  end

  private

  def api_changed?
    a = last_modified("app/controllers")
    b = last_modified("app/views/api")
    if a && b
      return a > b
    end
    return false
  end

  def last_modified(dir)
    File.mtime(Dir["#{dir}**/*"].map { |p| [ p, File.mtime(p) ] }.max { |a,b| a[1] <=> b[1] }[0]) rescue nil
  end

end
