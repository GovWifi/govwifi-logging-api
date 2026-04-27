# frozen_string_literal: true

class User < Sequel::Model(USER_DB[:userdetails])
  User.unrestrict_primary_key
end
