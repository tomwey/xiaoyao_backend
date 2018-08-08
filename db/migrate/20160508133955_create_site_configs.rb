class CreateSiteConfigs < ActiveRecord::Migration
  def change
    create_table :site_configs do |t|
      t.string :key,   null: false
      t.string :value, null: false
      t.string :description

      t.timestamps null: false
    end
    add_index :site_configs, :key, unique: true
  end
end
