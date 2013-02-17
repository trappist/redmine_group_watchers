# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'group_watchers/new', :controller=> 'group_watchers', :action => 'new', :via => :get
match 'group_watchers', :controller=> 'group_watchers', :action => 'create', :via => :post
match 'group_watchers/append', :controller=> 'group_watchers', :action => 'append', :via => :post
match 'group_watchers/destroy', :controller=> 'group_watchers', :action => 'destroy', :via => :post
match 'group_watchers/watch', :controller=> 'group_watchers', :action => 'watch', :via => :post
match 'group_watchers/unwatch', :controller=> 'group_watchers', :action => 'unwatch', :via => :post

