# frozen_string_literal: true

class Smoketests::SmoketestCleanup
  SESSION_BATCH_SIZE = 50
  def clean
    logger = Logger.new($stdout)
    logger.info("Starting daily smoke test user and session deletion")

    site_ips = ENV["SMOKE_TEST_IPS"].split(",").map(&:strip)
    total = Session.where(siteIp: site_ips).delete
    logger.info("Finished daily smoke test session deletion, #{total} rows affected")
  end
end
