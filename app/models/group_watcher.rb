class GroupWatcher < ActiveRecord::Base
  unloadable
  belongs_to :group
  belongs_to :watchable, :polymorphic => true
  validates_presence_of :group
  validates_uniqueness_of :group_id, :scope => [:watchable_type, :watchable_id]
end
