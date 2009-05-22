# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def http_status code
    codes = { "200" => "Ok",
             "201" => "Created",
             "400" => "Bad Request",
             "401" => "Unauthorized",
             "403" => "Forbidden",
             "404" => "Not Found",
             "409" => "Conflict",
             "500" => "Internal Server Error" }
    return codes[code].gsub(" ", "&nbsp;")
  end

  def usable?(array)
    defined?(array) && array && array.size > 0
  end

  # Create "show [link_value] listings on page" links for
  # each link value. Does it for feedback.
  def create_footer_pagination_links(link_values, type)
    links = []
    per_page_value = params[:per_page] || "10"
    params[:page] = 1 if params[:page]
    link_values.each do |value|
      if per_page_value.eql?(value)
        links << value
      else
        path = admin_feedbacks_path(params.merge({:per_page => value}))
       
        links << link_to(value, path)
      end
    end
    links.join(" | ")
  end

   # Changes line breaks to <br>-tags and transforms URLs to links
  def text_with_line_breaks(text)
    #pattern for ending characters that are not part of the url
    pattern = /[\.)]*$/
    h(text).gsub(/https?:\/\/\S+/) { |link_url| link_to(link_url.gsub(pattern,""), link_url.gsub(pattern,"")) +  link_url.match(pattern)[0]}.gsub(/\n/, "<br />")
  end
end
