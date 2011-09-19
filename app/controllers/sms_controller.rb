require 'net/http'
require 'net/https'

class SmsController < ApplicationController
  before_filter :fetch_pysmsd_config
  before_filter :ensure_client_login
  before_filter :ensure_sms_enabled
  verify :method => :post, 
    :only => :smssend, 
    :render => {:text => '405 HTTP POST required', :status => 405}
  verify :method => :put, 
    :only => :smsmark, 
    :render => {:text => '405 HTTP POST required', :status => 405}
  verify :method => :get, 
    :only => :index, 
    :render => {:text => '405 HTTP GET required', :status => 405}
  
  ##
  # return_code:: 200 - Returns SMSs fetched from pySMSd gateway for the logged in application
  # return_code:: 405 - Incorrect HTTP verb, only GET method allowed; OR SMS functionality not enabled
  # description:: ASI acts as a proxy and gets SMS stored at pySMSd as per the current application's name.
  def index
    @client_name = nil
    if session[:cos_session_id]
      if @application_session = Session.find_by_id(session[:cos_session_id])
        @client_name = Client.find_by_id(@application_session.client_id).name
      end
    end
    unless @client_name == nil
      http = get_http_connection()
      path = '/messages/in.json?name='+@pysmsd_config.app_name+'&password='+@pysmsd_config.app_password+'&keyword='+@client_name
      resp = http.get(path)
      json = JSON.parse(resp.body)
      json['messages'].each do | message |
        @person = Person.find_by_phone_number(message['number'])
        if @person
          message['user_id'] = @person.guid
        end
      end

      render_json :entry => json and return
    end
    render_json :status => :bad_request, :messages => "No matching application ID was found, cannot proceed to fetch SMS from server." and return
  end
 
  ##
  # return_code:: 200 - Message successfully marked as read in pySMSd database
  # return_code:: 405 - Incorrect HTTP verb, only PUT method allowed; OR SMS functionality not enabled
  # description:: Mark particular message as read at pySMSd. Once marked, messages will not appear in an index query.
  # 
  # params::
  #   ids:: A comma-delimited list of sms ids which to mark as read.
  def smsmark
    http = get_http_connection()    
    post_args = { 'ids' => params[:ids], 'name' => @pysmsd_config.app_name, 'password' => @pysmsd_config.app_password }
    request = Net::HTTP::Post.new('/messages/in.json')
    request.set_form_data(post_args)
    resp = http.request(request)
    json = JSON.parse(resp.body)
    render_json :entry => json
  end

  ##
  # return_code:: 200 - Message successfully sent
  # return_code:: 405 - Incorrect HTTP verb, only POST method allowed; OR SMS functionality not enabled
  # description:: Send one SMS message.
  #
  # params::
  #   number:: The number to which to send the message.
  #   text:: The text of the message.
  #   replyto:: Optional sms id to which the message is a reply. This has the effect of automatically marking the given message as read.
  def smssend
    http = get_http_connection()    
    post_args = { 'number' => params[:number], 'text' => params[:text],'replyto' => params[:replyto], 'name' => @pysmsd_config.app_name, 'password' => @pysmsd_config.app_password }
    
    request = Net::HTTP::Post.new('/messages/out.json')
    request.set_form_data(post_args)
    resp = http.request(request)
    json = JSON.parse(resp.body)
    render_json :entry => json
  end

  private

  def fetch_pysmsd_config
    @pysmsd_config = PysmsdConfig.where(:client_id => @application_session.client_id).first
    if @pysmsd_config.nil?
      @pysmsd_config = PysmsdConfig.new(:enabled => false)
    end
  end

  def ensure_sms_enabled
    unless @pysmsd_config.enabled
      render_json :status => 405, :messages => "SMS functionality is not currently enabled" and return
    end
  end
  #original implementation getting values from the config file
  #  def get_http_connection
  #    if APP_CONFIG.pysmsd_enabled
  #      if APP_CONFIG.pysmsd_use_proxy
  #        http = Net::HTTP::Proxy(APP_CONFIG.pysmsd_proxy_host, APP_CONFIG.pysmsd_proxy_port, APP_CONFIG.pysmsd_proxy_username, APP_CONFIG.pysmsd_proxy_password).new(APP_CONFIG.pysmsd_host, APP_CONFIG.pysmsd_port)
  #      else
  #        http = Net::HTTP.new(APP_CONFIG.pysmsd_host, APP_CONFIG.pysmsd_port)
  #     end
  #      http.use_ssl = APP_CONFIG.pysmsd_use_ssl
  #      return http
  #    end
  #  end
  def get_http_connection    
    unless @pysmsd_config.nil?
      if @pysmsd_config.enabled
        if @pysmsd_config.use_proxy
          http = Net::HTTP::Proxy(@pysmsd_config.proxy_host, @pysmsd_config.proxy_port, @pysmsd_config.proxy_username, @pysmsd_config.proxy_password).new(@pysmsd_config.host, @pysmsd_config.port)
        else
          http = Net::HTTP.new(@pysmsd_config.host, @pysmsd_config.port)
        end
        http.use_ssl = @pysmsd_config.use_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        return http
      end
    end
  end
end
