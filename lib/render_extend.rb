class ActionController::Base
  alias_method :old_render, :render

  def render(options = nil, extra_options = {}, &block)

    if options &&
       options[:json] &&
       options[:json].class == String &&
       (options[:json][0].chr != '{' && options[:json][0].chr != '[')

      options[:json] = "[#{options[:json]}]"
      
    end
    
    old_render options, extra_options, &block
  end
end
