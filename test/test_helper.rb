ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'factory'
begin
  require 'redgreen'
rescue Exception => e
  #Redgreen is copletely optional so no problem if not found :)
end

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  include Factory

  # Test the minimum or maximum length of an attribute.
  def assert_length(boundary, object, attribute, length, options = {})
    valid_char = options[:valid_char] || "a"
    barely_invalid = barely_invalid_string(boundary, length, valid_char)
    # Test one over the boundary.
    object[attribute] = barely_invalid
    assert !object.valid?,
    "#{object[attribute]} (length #{object[attribute].length}) " +
    "should raise a length error"
    #TODO: better assertion for this; doesn't work now because
    #error messages are modified from rails defaults
    #assert_equal correct_error_message(boundary, length), object.errors.on(attribute)

    # Test the boundary itself.
    barely_valid = valid_char * length
    object[attribute] = barely_valid
    assert object.valid?,
    "#{object[attribute]} (length #{object[attribute].length}) " +
    "should be on the boundary of validity"
  end

  # Create an attribute that is just barely invalid.
  def barely_invalid_string(boundary, length, valid_char)
    if boundary == :max
      invalid_length = length + 1
    elsif boundary == :min
      invalid_length = length - 1
    else
      raise ArgumentError, "boundary must be :max or :min"
    end
    valid_char * invalid_length
  end

  # Return the correct error message for the length test.
  def correct_error_message(boundary, length)
    error_messages = ActiveRecord::Errors.default_error_messages
    if boundary == :max
      sprintf(error_messages[:too_long], length)
    elsif boundary == :min
      sprintf(error_messages[:too_short], length)
    else
      raise ArgumentError, "boundary must be :max or :min"
    end
  end

  def login
    login_as(Person.first)
  end


  def login_as(person, client=nil)
    client ||= Client.find :first
    session = Session.new(:person => person, :client => client)
    session.save(false)
    @request.session[:cos_session_id] = session.id
  end
end

class ActionController::TestCase

  def assert_response(response, message=nil)
    super
    if @request.format == "application/json"
      if response == :success
        @json = JSON.parse(@response.body)
        unless @response.body.start_with? "{}"
          assert @json.key?("entry") || @json.key?("messages"), "No 'entry' or 'messages' in #{@response.body}"
        end
      elsif @response.body.start_with? "{" && response != :created
        @json = JSON.parse(@response.body)
        assert_nil json["entry"], "Illegal 'entry' in #{@response.body} with #{response}"
      end
      assert !(@response.body.start_with? "["), "No 'messages' in #{@response.body}"
      if @response.body.start_with? "{"
        @json = JSON.parse(@response.body)
        if @json.key?("messages")
          @json["messages"].each do |m|
            assert !m.start_with?("["), "Nested array in messages: #{@json.inspect}"
          end
        end
      end
    end
  end

end

module COSTestingDSL
  def logs_in_with(options)
    if expected_response = options[:expected_response]
      options.delete(:expected_response)
    else
      expected_response = :created
    end
    post "/session", { :session => options }
    assert_response expected_response
    assert_not_nil session[:cos_session_id] if expected_response == :created
  end

  def finds_collections(options)
    get "/appdata/#{options[:client_id]}/@collections"
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["entry"]
    assert_not_nil json["entry"][0]
    assert_not_nil json["entry"][0]["id"]
    return json["entry"][0]["id"]
  end

  def creates_collection(options)
    post "/appdata/#{options[:client_id]}/@collections"
    assert_response :created
#    assert_template "collections/create"
    json = JSON.parse(response.body)
    assert_not_nil json['entry']["id"]
    return json['entry']["id"]
  end

  def gets_collection(options)
    get "/appdata/#{options[:client_id]}/@collections/#{options[:id]}"
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json['entry']["id"]
    assert_not_nil json['entry']["entry"]
  end

  def adds_text_to_collection(options)
    post "/appdata/#{options[:client_id]}/@collections/#{options[:id]}",
    { :item => {:title => "Sleep Tight", :content_type => "text/plain", :body => "Lorem ipsum dolor sit amet." }}
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json['entry']["id"]
  end

  def deletes_collection(options)
    post "/appdata/#{options[:client_id]}/@collections/#{options[:id]}", { :_method => "DELETE" }
    assert_response :success
  end

  def tries_to_find_deleted_collection(options)
    get "/appdata/#{options[:client_id]}/@collections/#{options[:id]}"
    assert_response :not_found
  end

  def gets_person_details(options)
    get "/people/#{options[:id]}/@self"
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["entry"]["id"]
    assert_equal options[:id], json["entry"]["id"]
    return json
  end

  def updates_person_details_with(options)
    put "/people/#{options[:id]}/@self", options
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["entry"]["id"]
    #special handling for status_message
    if (options[:person][:status_message])
      options[:person][:status] = {:message => options[:person][:status_message]}
      options[:person].delete(:status_message)
    end
    #Don't expect email to be returned
    options[:person].delete(:email)
    assert subset(options[:person], json["entry"])
  end

  def changes_password_of_person(options)
    put "/people/#{options[:id]}/@self", {:person => { :password => options[:password] } }
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["entry"]["id"]
  end

  def deletes_account(options)
    delete "/people/#{options[:id]}/@self", options
    assert_response :success
    get "/people/#{options[:id]}/@self"
    assert_response :unauthorized
  end

  def logs_out
    delete "/session"
    assert_response :success
    assert_nil session[:cos_session_id]
  end

  def updates_location_with(options)
    put "/people/#{options[:id]}/@location", options[:location]
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json
  end

  def gets_location(options)
    get "/people/#{options[:id]}/@location", options
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json
  end

  def updates_avatar(options)
    put "/people/#{options[:id]}/@avatar", options
    assert_response :success
  end

  def creates_user_with(options)
    post "/people", {:person => options}
    assert_response :created, @response.body
  end

  def confirms_email_with(options)
    post "/confirmation", options
    assert_response :success, @response.body
    assert_nil(PendingValidation.find_by_key(options[:key]))
  end

  def creates_group_with(options)
    post "/groups", options
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"]["id"]
  end

  def lists_public_groups
    get "/groups/@public"
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"].collect {|g| g["id"]}
  end

  def lists_channels
    get "/channels/"
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"].collect {|c| c["name"]}
  end

  def searches_groups_with(query)
    get "/groups/@public", { :query => query }
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"].collect {|g| g["id"]}
  end

  def lists_membership_requests(group_id)
    get "/groups/@public/#{group_id}/@pending"
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"].collect {|g| g["id"]}
  end

  def joins_group(user_id, group_id)
    post "/people/#{user_id}/@groups", {:group_id => group_id}
    assert_response :success, @response.body
  end

  def leaves_group(user_id, group_id)
    delete "/people/#{user_id}/@groups/#{group_id}"
    assert_response :success, @response.body
  end

  def accepts_member(user_id, group_id)
    put "/people/#{user_id}/@groups/#{group_id}", { :accepted => "true" }
    assert_response :success, @response.body
  end

  def sends_group_invite_to(user_id, group_id)
    post "/people/#{user_id}/@groups/", { :group_id => group_id }
    assert_response :success, @response.body
  end

  def lists_membership_invites(user_id, group_id)
    get "/people/#{user_id}/@groups/@invites"
    assert_response :success, @response.body
    JSON.parse(@response.body)["entry"].collect {|g| g["id"]}
  end

  private

  def subset(a, b)
    if (a == b)
      return true
    end

    if (b == nil)
      return false
    end

    if (a.class.to_s == "String")
      return false
    end

    a.each do |key, value|
      if ! subset(value, b[key.to_s])
        return false
      end
    end
  end

end
