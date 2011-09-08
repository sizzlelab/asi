# -*- coding: utf-8 -*-

Factory.define :person do |f|
  f.sequence(:username) { |n| "kusti#{n}" }
  f.password "testi"
  f.sequence(:email) { |n| "working#{n}@address.com" }
  f.salt "ZB32fj38ueBG"
  f.status_message "Valid person rocks."
  f.status_message_changed "2008-08-28T10:58:12+03:00"
  f.birthdate "1940-06-01"
  f.gender "MALE"
  f.irc_nick "pelle"
  f.msn_nick "maison"
  f.phone_number "+358 40 834 7176"
  f.description "About me"
  f.website "http://example.com"
  f.association :name, :factory => :person_name
  f.association :address, :factory => :address
end

Factory.define :group do |f|
  f.sequence(:title) { |n| "An example group #{n}" }
  f.description "Groups can have descriptions. This is an example."
  f.group_type "open"
  f.association :creator, :factory => :person
end

Factory.define :location do |f|
  f.latitude 60.163389841749
  f.longitude 24.857125767506
  f.accuracy 58.0
  f.label "Otaniemen Alepa"
end

Factory.define :channel do |f|
  f.sequence(:name) { |n| "Chanel 9 #{n}" }
  f.description "Hethethethethethe"
  f.association :owner, :factory => :person
  f.association :creator_app, :factory => :client
  f.messages []

  f.after_create do |channel|
    f.association(:message, :channel => channel)
  end
end

Factory.define :message do |f|
  f.title "Title"
  f.body "This is the message body."
  f.content_type "text/plain"
  f.association :poster, :factory => :person
  f.association :channel, :factory => :channel
end

Factory.define :client do |f|
  f.sequence(:name) { |n| "Essi #{n}" }
  f.password "testi"
  f.encrypted_password "gibberish (not real encryption)"
end

Factory.define :person_name do |f|
  f.given_name "Essi"
  f.family_name "Esimerkki"
end

Factory.define :address do |f|
  f.street_address "Yrjö-Koskisenkatu 42"
  f.postal_code "00170"
  f.locality "Helsinki"
end
