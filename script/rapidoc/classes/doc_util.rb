require 'json'
require 'rdoc/rdoc'
require 'factory_girl_rails'
require File.join(File.dirname(__FILE__), '../../../lib/json_printer.rb')

class DocUtil

  # print some  erb code to a template
  def self.print_erb(str, show=false)
    (show ? "<%= " : "<% ") + str + " %>"
  end

  def self.pretty_print(value)
    begin
      data = eval(value, binding)
    rescue SyntaxError => e
      data = value
    end

    begin
      value = JSON.pretty_generate(JSON.parse(data.to_json))
      #value = CodeRay.scan(value, :json).div
      return value
    rescue JSON::ParserError => e
      puts "Parser error in #{data}"
      puts e.message
    end
  end

  def self.path_to_arr(path)
    path.split '/'
  end

  def self.arr_to_path(path)
    path.join '/'
  end

  def self.render_breadcrumb(path, breadcrumb_hash)
    ret = ""
    path_components = path_to_arr(path)
    path_components.each do |p|
      next if p == ''

      sub_path = breadcrumb_hash[p]
      if sub_path
        ret += '/' + render_path_to_a(sub_path, p)
      else
        ret += '/' + p
      end
    end
    return ret
  end

  def self.render_hash_to_dl(h)
    ret = "<dl>"
    h.each do |key, value|
      if value.instance_of? Hash
        ret += "<dt><span>" + key + "</span></dt>"
        ret += "<dd>"
        ret += render_hash_to_dl(value)
      elsif value.instance_of? Array
        ret += "<dt>" + key + "</dt>"
        ret += "<dd>"
        ret += render_array_to_p(value)
      else
        ret += "<dt>" + key + "</dt>"
        ret += "<dd>"
        ret += value
      end
      ret += "</dd>"
    end
    ret += "</dl>"
    return ret
  end

  def self.render_array_to_ul(a)
    ret = "<ul>"
    a.each do |p|
      ret += "<li>" + p + "</li>"
    end
    ret += "</ul>"
    return ret
  end

  def self.render_array_to_p(a)
    ret = ""
    a.each do |p|
      ret += "<p>" + p + "</p>"
    end
    return ret
  end

  def self.render_subresources_to_ul(subresources, subresources_index)
    ret = "<ul>"
    flag = false
    subresources_index.each do |i|
      if i.instance_of? Array
        ret += render_subresources_to_ul(subresources, i)
      else
        if flag
          ret += "</li>"
        end
        ret += "<li>"
        ret += render_path_to_a(subresources[i])
        flag = true
      end
    end
    ret += "</ul>"
    return ret
  end

  def self.render_path_to_a(res, label=nil)
    ret = '<a href="/doc' + res.delete(':') + '">'
    if label
      ret += format_resource_name(label)
    else
      ret += format_resource_name(res)
    end
    ret += '</a>' 
    return ret
  end

  def self.format_resource_name(res)
    res.gsub(/\/:([^\/]*)/, '/&lt;\1&gt;')
  end


  def self.extract_info(document)
    ret = {
      :description => get_text_by_label(document, 'description'),
      :access => get_text_by_label(document, 'access'),
      :return_codes => get_text_by_label(document, 'return_code'),
      :json => get_text_by_label(document, 'json'),
      :params => get_list_by_label(document, 'params')
    }
    if ret[:json]
      ret[:json] = ret[:json].join("\n")
    end
    return ret
  end

  def self.get_list(node)
    ret = {}
    node.items.each do |item|
      if item.instance_of?(RDoc::Markup::ListItem)
        if !item.parts.empty? && item.parts[0].instance_of?(RDoc::Markup::List)
          ret[item.label] = get_list(item.parts[0])
        else
          ret[item.label] = get_text(item.parts)
        end
      end
    end
    return ret
  end

  def self.get_list_by_label(node, label)
    ret = {}
    n = get_nodes_by_label(node, label)
    if !n.empty? && !n[0].parts.empty?
      ret = get_list(n[0].parts[0])
    end
    return ret
  end

  def self.get_text_by_label(node, label)
    return get_text(get_nodes_by_label(node, label))
  end

  def self.get_text(node_array)
    ret = []
    node_array.each do |node|
      if node && node.respond_to?(:parts)
        node.parts.each do |p|
          if p.instance_of? RDoc::Markup::Paragraph
            ret << p.parts
          elsif p.instance_of? String
            ret << p
          end
        end
      end
    end
    return ret.flatten
  end

  def self.get_nodes_by_label(node, label)
    ret = []

    if node.respond_to?(:label) && node.label == label
      ret << node
    end

    if node.respond_to?(:items)
      parts = node.items
    elsif node.respond_to?(:parts)
      parts = node.parts
    else
      return ret
    end

    parts.each do |p|
      n = get_nodes_by_label(p, label)
      if !n.empty?
        ret << n
      end
    end
    return ret.flatten
  end

end

