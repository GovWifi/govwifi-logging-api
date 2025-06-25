Sequel.migration do
  change do
    alter_table :sessions do
      add_index :mac
    end
  end
end
