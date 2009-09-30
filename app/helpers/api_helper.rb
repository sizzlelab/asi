module ApiHelper

  def doc_title(text)
    #text = text
    link = "<h1><code>#{link_to('ASI', root_url)}"

    text.split("/").inject do |sum, part|
      parturl = part.gsub("&lt;", "").gsub("&gt;", "")
      begin
        ActionController::Routing::Routes.recognize_path("/api" + "#{sum}/#{parturl}")
        link += "/" + link_to_unless_current(part, "/api" + "#{sum}/#{parturl}")
        sum + "/" + parturl
      rescue ActionController::RoutingError
        link += "/#{part}"
        sum + "/" + parturl
      end
    end

    link += "</code></h1>"
  end

  def link_to_api(api)
    link_to(api, api)
  end

end
