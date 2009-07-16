class DocUtil
  # print some  erb code to a template
  def self.print_erb(str, show=false)
    (show ? "<%= " : "<% ") + str + " %>"
  end
  
end