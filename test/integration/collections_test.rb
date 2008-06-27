require 'test_helper'
require 'json'

class CollectionsTest < ActionController::IntegrationTest
  fixtures :collections, :people, :clients, :connections

  def test_find_collection
    new_session do |ossi|
      ossi.logs_in_with :user_id => people(:friend).id, :client_id => clients(:one).id
      collection_id = ossi.finds_collections :client_id => clients(:one).id
      
      options = { :client_id => clients(:one).id, :id => collection_id }
      
      ossi.gets_collection options
      ossi.adds_text_to_collection options
      ossi.deletes_collection options
      ossi.logs_out
    end
  end

  def test_create_and_delete_collection
    new_session do |ossi|
      ossi.logs_in_with :user_id => people(:friend).id, :client_id => clients(:one).id
      collection_id = ossi.creates_collection :client_id => clients(:one).id
     
      options = { :client_id => clients(:one).id, :id => collection_id }
      
      ossi.deletes_collection options
      ossi.tries_to_find_deleted_collection options
      ossi.logs_out
    end
  end

  private

    module COSTestingDSL
      def logs_in_with(options)
        post "/session", options
        assert_response :success
        assert_not_nil session["user"]
        assert_not_nil session["client"]
      end
      
      def finds_collections(options)
        get "/appdata/#{options[:client_id]}/@collections"
        assert_response :success
        assert_template "collections/index"
        json = JSON.parse(response.body)
        assert_not_nil json["entry"]
        assert_not_nil json["entry"][0]
        assert_not_nil json["entry"][0]["id"]
        return json["entry"][0]["id"]
      end

      def creates_collection(options)
        post "/appdata/#{options[:client_id]}/@collections"
        assert_response :success
        assert_template "collections/create"
        json = JSON.parse(response.body)
        assert_not_nil json["id"]
        return json["id"]
      end

      def gets_collection(options)
        get "/appdata/#{options[:client_id]}/@collections/#{options[:id]}"
        assert_response :success
        json = JSON.parse(response.body)
        assert_not_nil json["id"]
        assert_not_nil json["entry"]
      end

      def adds_text_to_collection(options)
        post "/appdata/#{options[:client_id]}/@collections/#{options[:id]}", 
        { :title => "Sleep Tight", :content_type => "text/plain", :body => "Lorem ipsum dolor sit amet." }
        assert_response :success
        json = JSON.parse(response.body)
        assert_not_nil json["id"]
      end

      def deletes_collection(options)
        delete "/appdata/#{options[:client_id]}/@collections/#{options[:id]}"
        assert_response :success
      end

      def tries_to_find_deleted_collection(options)
        get "/appdata/#{options[:client_id]}/@collections/#{options[:id]}"
        assert_response :not_found
      end

      def logs_out
        delete "/session"
        assert_response :success
        assert_nil session["user"]
        assert_nil session["client"]
      end

    end

    def new_session
      open_session do |sess|
        sess.extend(COSTestingDSL)
        yield sess if block_given?
      end
    end
end
