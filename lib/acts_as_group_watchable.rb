# ActsAsWatchable
module Redmine
  module Acts
    module GroupWatchable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_group_watchable(options = {})
          #return if self.included_modules.include?(Redmine::Acts::Watchable::InstanceMethods)
          class_eval do
            has_many :group_watchers, :as => :watchable, :dependent => :delete_all
            has_many :watcher_groups, :through => :group_watchers, :source => :group, :validate => false

            scope :watched_by, lambda { |user_id| { 
              :include => [:watchers, :group_watchers],
              :conditions => ["#{Watcher.table_name}.user_id = ? OR #{GroupWatcher.table_name}.group_id in (?)", user_id, User.find(user_id).group_ids] 
            } }
            attr_protected :group_watcher_ids, :watcher_user_ids
          end
          send :include, Redmine::Acts::GroupWatchable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        # Adds user as a watcher
        def add_group_watcher(group)
          self.group_watchers << GroupWatcher.new(:group => group)
        end

        def addable_watcher_groups
          Group.sorted.where("id not in (?)", group_watcher_ids+[0])
        end

        # Removes user from the watchers list
        def remove_group_watcher(group)
          return nil unless group && group.is_a?(Group)
          GroupWatcher.delete_all "watchable_type = '#{self.class}' AND watchable_id = #{self.id} AND group_id = #{group.id}"
        end

        # Adds/removes watcher
        def set_group_watcher(group, watching=true)
          watching ? add_group_watcher(group) : remove_group_watcher(group)
        end

        # Overrides watcher_user_ids= to make user_ids uniq
        def watcher_group_ids_with_uniq_ids=(group_ids)
          if group_ids.is_a?(Array)
            group_ids = group_ids.uniq
          end
          send :watcher_group_ids_without_uniq_ids=, group_ids
        end

        def group_watched_by?(group)
          group_watcher_ids.include?(group.id) if group
        end

        def watcher_users_through_groups
          User.in_groups(group_watchers.map(&:group_id))
        end

        # Overrides method from acts_as_watchable to include group members
        def notified_watchers
          notified = (watcher_users.active + watcher_users_through_groups.active).uniq
          notified.reject! {|user| user.mail.blank? || user.mail_notification == 'none'}
          if respond_to?(:visible?)
            notified.reject! {|user| !visible?(user)}
          end
          notified
        end

        module ClassMethods; end
      end
    end
  end
end
