require File.join(File.dirname(__FILE__), '../../../lib/json_printer.rb')
require 'json'
require File.join(File.dirname(__FILE__), '../../../test/factory.rb')

class DocUtil

  # print some  erb code to a template
  def self.print_erb(str, show=false)
    (show ? "<%= " : "<% ") + str + " %>"
  end

  def self.pretty_print(value)

    begin
      data = eval(value)
    rescue SyntaxError => e
      puts value
#      data = JSON.parse(value)
    end
    begin

      value = JSON.pretty_generate(JSON.parse(JSON.pretty_generate(data)))
    rescue JSON::ParserError => e
      puts "Parser error in #{data}"
      puts e.message
    end

  end

end
