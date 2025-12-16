Sequel.migration do
  change do
    alter_table :sessions do
      add_column :eap_type, String, default: ""
      # Username for SSL client certs seem to be email addresses. 254 is max
      # length for an email address as per RFC 5321.
      add_column :ssl_username, String,  size: 254, default: ""
    end
  end
end
