module SimpleGroups
  module UserExtensions
    def self.included( base )
      base.extend( ClassMethods )
    end
    
    module ClassMethods
      def include_simple_groups
        has_many :memberships, :dependent => :destroy
        has_many :groups, :through => :memberships, :conditions => 'accepted_at IS NOT NULL'
        has_many :pending_groups, :through => :memberships, :source => :group, :conditions => 'accepted_at IS NULL AND inviter_id IS NULL'
        has_many :invited_groups, :through => :memberships, :source => :group, :conditions => 'accepted_at IS NULL AND inviter_id IS NOT NULL'
        
        include SimpleGroups::UserExtensions::InstanceMethods #see below
      end
    end

    module InstanceMethods
      def is_member_of?(group)
        self.groups.include?(group)     
      end

      def is_admin_of?(group)
        self.membership(group).admin_role if self.is_member_of?(group)
      end

      def request_membership_of(group)
        return group.request_membership(self)
      end

      def membership(group)
        group.membership(self)
      end

      def leave(group)
        self.membership(group).destroy if self.is_member_of?(group)
      end

      def accept_member(person, group)
        group.accept_member(person) if self.is_admin_of?(group)
      end

      def invite(person, group)
        group.invite(person, self)
      end
    end
  end
end
