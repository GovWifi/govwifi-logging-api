Sequel.migration do
  change do
    alter_table :sessions do
      add_column :eap_type, String, default: ""
    end
  end
end
