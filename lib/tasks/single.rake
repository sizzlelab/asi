##
# Run a single test in Rails.
#
#   rake blogs_list
#   => Runs test_list for BlogsController (functional test)
#
#   rake blog_create
#   => Runs test_create for BlogTest (unit test)

rule "" do |t|
  if /(.*)_([^.]+)$/.match(t.name)
    file_name = $1
    test_name = $2
    if File.exist?("test/unit/#{file_name}_test.rb")
      file_name = "unit/#{file_name}_test.rb" 
    elsif File.exist?("test/functional/#{file_name}_controller_test.rb")
      file_name = "functional/#{file_name}_controller_test.rb" 
    else
      raise "No file found for #{file_name}" 
    end
    sh "ruby -Ilib:test test/#{file_name} -n /^test_#{test_name}/" 
  end
end
