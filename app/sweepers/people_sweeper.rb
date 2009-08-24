class PeopleSweeper < ActionController::Caching::Sweeper
  
  observe Person, Image
  
  def after_create(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
    set_modified_timestamp
  end
  
  def after_update(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
    set_modified_timestamp
  end
  
  def after_delete(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
    set_modified_timestamp
  end
  
  private
  
  def expire_cache_for(person)
    if !person
      return
    end
    Rails.cache.delete(Person.build_cache_key(person))
  end
  
  def set_modified_timestamp
    Rails.cache.write(Person.build_cache_key(:person_modified), Time.now)
  end
  
end