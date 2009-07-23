require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'
require "#{RAILS_ROOT}/vendor/plugins/thinking-sphinx/lib/thinking_sphinx/tasks"

class SystemController < ApplicationController

  before_filter :ensure_localhost
  skip_after_filter :log
  layout nil

  def reindex
    system "rake thinking_sphinx:rebuild RAILS_ENV=#{ENV['RAILS_ENV']} &"
    render :template => "system/default"
  end

  def upload
    CachedCosEvent.upload_all
    render :template => "system/default"
  end

  private

  def ensure_localhost
    unless request.host == "localhost"
      render :status => :forbidden, :template => "system/default"
    end
  end

end