#require 'rake'
#require 'rake/testtask'
#require 'rake/rdoctask'
#require 'tasks/rails'
#require "#{Rails.root.to_s}/vendor/plugins/thinking-sphinx/lib/thinking_sphinx/tasks"

class SystemController < ApplicationController

  before_filter :ensure_localhost
  skip_after_filter :log
  layout nil

  def reindex
    rake "thinking_sphinx:rebuild"
    render :template => "system/default"
  end

  def upload
    if  APP_CONFIG.log_to_ressi
      rake "ressi:upload"
      render :template => "system/default"
    end
  end

  def clean_sessions
    Session.cleanup
    render :template => "system/default"
  end

  private

  def ensure_localhost
    unless request.local? || Rails.env.test?
      render :status => :forbidden, :template => "system/default"
    end
  end

  def rake(task)
    system "rake #{task} RAILS_ENV=#{Rails.env.to_s} > /dev/null &"
  end

end
