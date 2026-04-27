# frozen_string_literal: true

class Performance::Repository::SignUp < Sequel::Model(USER_DB[:userdetails])
  dataset_module do
    def all(date)
      where(Sequel.lit("date(created_at) <= '#{date - 1}'"))
    end

    def day_before(date)
      where(Sequel.lit("date(created_at) = '#{date - 1}'"))
    end

    def self_sign
      where(contact: Sequel[:sponsor])
    end

    def sponsored
      exclude(contact: Sequel[:sponsor])
    end

    def with_sms
      where(Sequel.like(:contact, "+%"))
    end

    def with_email
      where(Sequel.like(:contact, "%@%"))
    end

    def week_before(date)
      yesterday = date.prev_day
      where(Sequel.lit("date(created_at) BETWEEN '#{yesterday - 6}' AND '#{yesterday}'"))
    end

    def month_before(date)
      where(Sequel.lit("date(created_at) BETWEEN '#{date.prev_month}' AND '#{date.prev_day}'"))
    end

    def with_successful_login
      exclude(last_login: nil)
    end

    def new_active_users(start_date, end_date)
      where { created_at >= start_date }.where { created_at <= end_date }.exclude(last_login: nil).count
    end

    def new_inactive_users(start_date, end_date)
      where { created_at >= start_date }.where { created_at <= end_date }.where(last_login: nil).count
    end
  end
end
