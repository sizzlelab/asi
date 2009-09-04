module ApiHelper

  def http_status code
    codes = { "200" => "Ok",
             "201" => "Created",
             "202" => "Accepted",
             "203" => "Non-authoritative Information",
             "400" => "Bad Request",
             "401" => "Unauthorized",
             "403" => "Forbidden",
             "404" => "Not Found",
             "409" => "Conflict",
             "500" => "Internal Server Error" }
    return codes[code].gsub(" ", "&nbsp;")
  end

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
