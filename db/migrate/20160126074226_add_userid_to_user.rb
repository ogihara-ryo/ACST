class AddUseridToUser < ActiveRecord::Migration
  def change
    add_column :users, :userid, :string
  end
end
