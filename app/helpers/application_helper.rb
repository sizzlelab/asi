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
    return codes[code]
  end
end
