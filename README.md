# Redmine Group Watchers

This is a plugin for Redmine 2.x which adds the possibility of adding groups as watchers on issues.

To install:

```
cd path_to_redmine/plugins
git clone git@github.com:trappist/redmine_group_watchers.git group_watchers
cd ..
bundle install
bundle exec rake redmine:plugins:migrate
```

And restart Redmine
