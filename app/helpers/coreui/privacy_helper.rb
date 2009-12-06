module Coreui::PrivacyHelper

  # In the right format for options_for_select helper.
  PRIVACY_PRESETS = [
    ["Everyone", "public"],
    ["Logged in users", "logged_in"],
    ["Friends only", "friends_only"],
    ["Only me", "private"]
  ]

  def privacy_preset(key)
    PRIVACY_PRESETS.each do |array|
      return array if array.include?(key)
    end
    return ["???"] # Testing
  end

  def privacy_presets(default_preset)
    [["Default (#{privacy_preset(default_preset)[0]})", "default"]].concat(PRIVACY_PRESETS)
    PRIVACY_PRESETS
  end

  def keyword(condition_action_set)
    return nil if not condition_action_set
    condition = condition_action_set.condition
    PRIVACY_PRESETS.detect do |a|
      regex = "^#{a[1]}$"
      condition.condition_value.match(regex) || condition.condition_type.match(regex)
    end
  end
end
