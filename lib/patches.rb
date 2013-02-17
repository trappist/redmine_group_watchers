module Redmine
  module Acts
    module Watchable
      module InstanceMethods
        def addable_watcher_users
          users = self.project.users.sort - self.watcher_users
          if respond_to?(:visible?)
            users.reject! {|user| !visible?(user)}
          end
          groups = Group.sorted #- self.watcher_groups
          groups + users
        end
      end
    end
  end
end


module GroupWatchers

  module Patches

    module IssueModelPatch
      def self.included(base)
        base.class_eval do
          acts_as_group_watchable
        end
      end
    end

    module WatchersControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :create, :groups
          alias_method_chain :append, :groups
        end
      end
      module InstanceMethods
        def create_with_groups
          if params[:watcher].is_a?(Hash) && request.post?
            principal_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
            users =  User.active.where(:id => principal_ids)
            groups = Group.active.where(:id => principal_ids)
            users.each do |user|
              Watcher.create(:watchable => @watched, :user_id => user.id)
            end
            groups.each do |group|
              GroupWatcher.create(:watchable => @watched, :group_id => group.id)
            end
          end
          respond_to do |format|
            format.html { redirect_to_referer_or {render :text => 'Watcher added.', :layout => true}}
            format.js
          end
        end
        def append_with_groups
          if params[:watcher].is_a?(Hash)
            principal_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
            @users  = User.active.where(:id => principal_ids)
            @groups = Group.active.where(:id => principal_ids)
          end
        end
      end
    end

    module UserModelPatch
      def self.included(base)
        base.class_eval do
          scope :in_groups, lambda {|groups|
            group_ids = groups.first.is_a?(Group) ? groups.map(:id) : groups.map(&:to_i)
            where("#{User.table_name}.id IN (SELECT gu.user_id FROM #{table_name_prefix}groups_users#{table_name_suffix} gu WHERE gu.group_id in (?))", group_ids)
          }
        end
      end
    end

    module WatchersHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :watchers_list, :groups
          alias_method_chain :watchers_checkboxes, :groups
          alias_method_chain :watcher_link, :group
        end
      end
      module InstanceMethods
        def watchers_list_with_groups(object)
          remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
          url_hash = {:controller => 'group_watchers', :action => 'destroy', :object_type => object.class.to_s.underscore}
          content = ''.html_safe
          lis = object.watcher_users.collect do |user|
            s = ''.html_safe
            s << avatar(user, :size => "16").to_s
            s << link_to_user(user, :class => 'user')
            if remove_allowed
              url = url_hash.merge(:object_id => object.id, :user_id => user, :controller => 'watchers')
              s << ' '
              s << link_to(image_tag('delete.png'), url, :remote => true, :method => 'post', :style => "vertical-align: middle", :class => "delete")
            end
            content << content_tag('li', s)
          end
          group_head = "#{l(:label_issue_group_watchers)} (#{object.watcher_groups.size})"
          content << content_tag('h3', group_head)
          glis = object.watcher_groups.collect do |group|
            s = ''.html_safe
            s << link_to(group.name, group, :class => 'group')
            if remove_allowed
              url = url_hash.merge(:object_id => object.id, :group_id => group)
              s << ' '
              s << link_to(image_tag('delete.png'), url, :remote => true, :method => 'post', :style => 'vertical-align: middle', :class => 'delete')
            end
            content << content_tag('li', s)
          end
          content.present? ? content_tag('ul', content) : content
        end

        def watchers_checkboxes_with_groups(object, users, checked=nil)
          user_list = users.map do |user|
            c = checked.nil? ? object.watched_by?(user) : checked
            tag = check_box_tag 'issue[watcher_user_ids][]', user.id, c, :id => nil
            content_tag 'label', "#{tag} #{h(user)}".html_safe,
                        :id => "issue_watcher_user_ids_#{user.id}",
                        :class => "floating"
          end
          splitter = ["</span></p><p><span><label>#{l(:label_issue_group_watchers)}</label>"]
          group_list = Group.all.map do |group|
            tag = check_box_tag 'issue[group_watcher_ids][]', group.id, object.group_watched_by?(group), :id => nil
            content_tag 'label', "#{tag} #{h(group)}".html_safe,
                        :id => "issue_watcher_group_ids_#{group.id}",
                        :class => "floating"
          end
          closer = ["</p>"]
          (user_list+splitter+group_list+closer).join.html_safe
        end

        def watcher_link_with_group(object, user_or_group)
          if user_or_group.is_a?(User)
            return '' unless user_or_group && user_or_group.logged? && object.respond_to?('watched_by?')
            watched = object.watched_by?(user_or_group)
          else
            return '' unless group && object.respond_to?('group_watched_by?')
            watched = object.group_watched_by?(user_or_group)
          end
          url = {:controller => 'watchers',
                 :action => (watched ? 'unwatch' : 'watch'),
                 :object_type => object.class.to_s.underscore,
                 :object_id => object.id}
          url.merge!(:controller => 'group_watchers') if user_or_group.is_a?(Group)
          link_to((watched ? l(:button_unwatch) : l(:button_watch)), url,
                  :remote => true, :method => 'post', :class => (watched ? 'icon icon-fav' : 'icon icon-fav-off'))
        end

      end
    end
  end
end

unless Issue.included_modules.include? GroupWatchers::Patches::IssueModelPatch
  Issue.send(:include, GroupWatchers::Patches::IssueModelPatch)
end

unless User.included_modules.include? GroupWatchers::Patches::UserModelPatch
  User.send(:include, GroupWatchers::Patches::UserModelPatch)
end

unless WatchersHelper.included_modules.include? GroupWatchers::Patches::WatchersHelperPatch
  WatchersHelper.send(:include, GroupWatchers::Patches::WatchersHelperPatch)
end

unless WatchersController.included_modules.include? GroupWatchers::Patches::WatchersControllerPatch
  WatchersController.send(:include, GroupWatchers::Patches::WatchersControllerPatch)
end
