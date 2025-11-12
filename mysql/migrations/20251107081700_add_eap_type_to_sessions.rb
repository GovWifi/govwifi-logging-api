Sequel.migration do
  change do
    alter_table :sessions do
      add_column :eap_type, String, default: ""
      # Increase username size to accommodate longer usernames such as email
      # addresses which come in via some EAP types.
      set_column_type :username, String, size: 254
    end
  end
end
