module SimpleGroups
  module UserExtensions
    def self.included( base )
      base.extend( ClassMethods )
    end
    
    module ClassMethods
      def include_simple_groups
        has_many :memberships, :dependent => :destroy
        has_many :groups, :through => :memberships#, :conditions => 'accepted_at IS NOT NULL'
        has_many :pending_groups, :through => :memberships, :source => :group, :conditions => 'accepted_at IS NULL'
        
        include SimpleGroups::UserExtensions::InstanceMethods
      end
    end

    module InstanceMethods
      # methods created for group_plugin
      def is_member_of?(group)
        #puts self.groups.inspect + "hox"
        self.groups.include?(group)     
      end

      def is_admin_of?(group)
        self.membership(group).admin_role if self.is_member_of?(group)
      end

      def request_membership_of(group)
        group.members << self unless self.is_member_of?(group)
      end

      def pending_and_accepted_groups
        #puts "Kysyttiin acc ja pen GROUPS: ACC: #{self.groups} ja PEN: #{self.pending_groups  } "
        self.pending_groups + self.groups
        
      end

      # use group object to find the membership associated. Use mainly in other methods.
      def membership(group)
        Membership.find(:first, :conditions => ['person_id = ? AND group_id = ?', self.id, group.id])
      end

      def leave(group)
        self.membership(group).destroy if self.is_member_of?(group)
      end
      
      def become_member_of(group)
        #puts self.pending_and_accepted_groups.inspect + "R1"
        #self.groups
        #group.members << self unless self.pending_and_accepted_groups.include?(group)
        if group.add_member(self) #unless self.pending_and_accepted_groups.include?(group)
          if group.accept_member(self)
            group.save
            return true
          end
        end
        return false
        #puts self.pending_and_accepted_groups.inspect + "RRR"
        #puts "#{group.members.inspect} Group members at the moment"
          # group.members.push self 
          # puts self.pending_and_accepted_groups.inspect + "RRR222"
          # puts group.members.inspect + "PAX"
        
          
         # puts "#{group.members.inspect} Group after acceptt"
      end
    end
  end
end