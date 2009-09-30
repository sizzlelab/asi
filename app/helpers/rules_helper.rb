module RulesHelper
  def add_condition_link(name)
    link_to_function name do |page|
    page.insert_html :bottom, :conditions, :partial => 'condition', :object => 'condition_action_set'
  end
  end
end