require 'test_helper'

class CosEventTest < ActiveSupport::TestCase

  def test_create
    # These tests require that the Ressi server is running at RESSI_URL
    if RESSI_URL && LOG_TO_RESSI
      begin



        test_event = CosEvent.new({
          :user_id => 'bU8aHSBEKr3AhYaaWPEYjL',
          :application_id => 'cWslSQyIyr3yiraaWPEYjL',
          :cos_session_id => 'BAh7BzoPc2Vzc2lvbl9pZGkCVREiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xs ZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA=--e3ae3baef1b6f0e680af4107e0f086b5f59f0da6',
          :ip_address => '130.233.194.26',
          :action => 'PeopleController#pending_friend_requests',
          :parameters => '{"format": "json", "action": "pending_friend_requests", "controller": "people", "user_id": "bU8aHSBEKr3AhYaaWPEYjL"}', # JSON
          :return_value => '200',
          :headers => '{"SERVER_NAME": "ossi.alpha.sizl.org", "HTTP_MAX_FORWARDS": "10", "HTTP_X_PROTOTYPE_VERSION": "1.6.0.2", "PATH_INFO": "/people/bU8aHSBEKr3AhYaaWPEYjL/@pending_friend_requests", "HTTP_X_FORWARDED_HOST": "ossi.alpha.sizl.org", "HTTP_VIA": "1.1 ossi.alpha.sizl.org", "HTTP_ACCEPT_ENCODING": "gzip,deflate", "HTTP_USER_AGENT": "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.5) Gecko/2008120121 Firefox/3.0.5", "SCRIPT_NAME": "/", "SERVER_PROTOCOL": "HTTP/1.1", "HTTP_ACCEPT_LANGUAGE": "en-us,en;q=0.5", "HTTP_HOST": "ossi.alpha.sizl.org", "REMOTE_ADDR": "127.0.0.1", "SERVER_SOFTWARE": "Mongrel 1.1.5", "REQUEST_PATH": "/people/bU8aHSBEKr3AhYaaWPEYjL/@pending_friend_requests", "HTTP_REFERER": "http://ossi.alpha.sizl.org/jsclient/v1/", "HTTP_COOKIE": "_trunk_session=BAh7BzoPc2Vzc2lvbl9pZGkCVREiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xs%0AZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA%3D--e3ae3baef1b6f0e680af4107e0f086b5f59f0da6", "HTTP_ACCEPT_CHARSET": "ISO-8859-1,utf-8;q=0.7,*;q=0.7", "HTTP_VERSION": "HTTP/1.1", "HTTP_X_FORWARDED_SERVER": "ossi.alpha.sizl.org", "REQUEST_URI": "/people/bU8aHSBEKr3AhYaaWPEYjL/@pending_friend_requests", "SERVER_PORT": "80", "GATEWAY_INTERFACE": "CGI/1.2", "HTTP_X_FORWARDED_FOR": "130.233.194.26", "HTTP_ACCEPT": "text/javascript, text/html, application/xml, text/xml, */*", "HTTP_CONNECTION": "Keep-Alive", "HTTP_X_REQUESTED_WITH": "XMLHttpRequest", "REQUEST_METHOD": "GET"}'
          })
        assert(test_event.valid?, "event not valid.")
        assert test_event.save
        assert_not_nil(test_event)
      rescue Errno::ECONNREFUSED => e
        puts "No connection to RESSI at #{RESSI_URL}"
      end

    end
  end

end
