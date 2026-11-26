Sequel.migration do
  change do
    alter_table :sessions do
      add_column :cert_valid_since, :datetime, null: true, default: nil
      add_column :cert_expiration, :datetime, null: true, default: nil
    end
  end
end
