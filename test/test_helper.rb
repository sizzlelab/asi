ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
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

  # Test the minimum or maximum length of an attribute.
  def assert_length(boundary, object, attribute, length, options = {})
    valid_char = options[:valid_char] || "a"
    barely_invalid = barely_invalid_string(boundary, length, valid_char)
    # Test one over the boundary.
    object[attribute] = barely_invalid
    assert !object.valid?,
    "#{object[attribute]} (length #{object[attribute].length}) " +
    "should raise a length error"
    assert_equal correct_error_message(boundary, length), 
    object.errors.on(attribute) 

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
  
  def login_as(person)
    @request.session[:person_id] = people(person).id
  end

end

module COSTestingDSL
  def logs_in_with(options)
    post "/session", options
    assert_response :success
    assert_not_nil session[:session_id]
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
    assert_not_nil json["id"]
    assert_equal options[:id], json["id"]
  end

  def updates_person_details_with(options)
    put "/people/#{options[:id]}/@self", options
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["id"]
    assert subset(options[:person], json)
  end

  def deletes_account(options)
    delete "/people/#{options[:id]}/@self", options
    assert_response :success
  end

  def logs_out
    delete "/session"
    assert_response :success
    assert_nil session["session_id"]
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
