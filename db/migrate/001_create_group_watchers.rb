class CreateGroupWatchers < ActiveRecord::Migration
  def change
    create_table :group_watchers do |t|
      t.integer :watchable_id
      t.string :watchable_type
      t.integer :group_id
    end
  end
end
