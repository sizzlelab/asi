class CollapsePersonSpecToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :status_message, :string
    add_column :people, :status_message_changed, :datetime
    add_column :people, :gender, :string
    add_column :people, :irc_nick, :string
    add_column :people, :msn_nick, :string
    add_column :people, :phone_number, :string
    add_column :people, :description, :string
    add_column :people, :website, :string
    add_column :people, :birthdate, :date
  end

  def self.down
    remove_column :people, :status_message
    remove_column :people, :status_message_changed
    remove_column :people, :gender
    remove_column :people, :irc_nick
    remove_column :people, :msn_nick
    remove_column :people, :phone_number
    remove_column :people, :description
    remove_column :people, :website
    remove_column :people, :birthdate
  end
end
