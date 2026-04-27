# frozen_string_literal: true

class Gdpr::Gateway::SetLastLogin
  def set(date:, usernames:)
    usernames.each_slice(100) do |usernames_slice|
      User
        .where([[:username, usernames_slice]])
        .update(last_login: date)
    end
  end
end
