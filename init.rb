ActionDispatch::Callbacks.to_prepare do
  require_dependency 'acts_as_watchable'
  require_dependency 'acts_as_group_watchable'
  ActiveRecord::Base.send(:include, Redmine::Acts::GroupWatchable)
  require_dependency 'group_watchers_patches'
  # Let deface load from the plugin dir
  Rails.application.paths.add "app/overrides", :with => ["plugins/#{File.basename(File.expand_path(File.dirname(__FILE__)))}/app/overrides"]
end

Redmine::Plugin.register :group_watchers do
  name 'Redmine Group Watchers'
  author 'Rocco Stanzione'
  description 'Add groups as watchers on Redmine issues'
  version '0.0.1'
  url 'http://github.com/trappist/redmine_group_watchers'
  author_url 'http://github.com/trappist'
end
