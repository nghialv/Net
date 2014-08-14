class CreateMyFiles < ActiveRecord::Migration
  def change
    create_table :my_files do |t|
      t.string :name
      t.binary :data

      t.timestamps
    end
  end
end
