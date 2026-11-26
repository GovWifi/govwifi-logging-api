FactoryBot.define do
  factory :session, class: Session do
    to_create(&:save)
    siteIP { Faker::Internet.ip_v4_address }
    username { Faker::Alphanumeric.alpha(number: 6) }
    start { Time.now }
    mac { Faker::Internet.mac_address }
    success { 1 }

    trait :failed do
      success { 0 }
    end

    trait :cba do
      username { nil }
      cert_serial { Faker::Number.number(digits: 15) }
      transient do
        issuing_org { Faker::Company.name }
      end
      cert_issuer do
        "/CN=#{Faker::Name.name}/O=#{issuing_org}/C=uk"
      end
      cert_subject do
        "/CN=#{Faker::Name.name}/O=#{issuing_org}/C=uk"
      end
      transient do
        cert_valid_since { 2.years.ago }
        cert_expiration { 5.years.from_now }
      end
    end
  end
end
