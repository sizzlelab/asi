class PeopleSweeper < ActionController::Caching::Sweeper
  
  observe Person, Image
  
  def after_create(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
  end
  
  def after_update(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
  end
  
  def after_delete(item)
    person = (item.is_a?(Image) ? item.person.guid : item.guid)
    expire_cache_for(person)
  end
  
  private
  
  def expire_cache_for(person)
    if !person
      return
    end
    Rails.cache.delete(Person.build_cache_key(person))
  end
  
end