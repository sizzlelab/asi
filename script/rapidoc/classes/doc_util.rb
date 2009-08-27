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
      data = JSON.parse(value)
    end
    p "foo"
    value = JSON.pretty_generate(data)
  end

end
