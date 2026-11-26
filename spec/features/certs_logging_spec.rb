describe App do
  before do
    DB[:sessions].truncate
    USER_DB[:userdetails].truncate
  end

  describe "certificate post-auth logging with POST" do
    shared_examples "logging" do
      let(:request_body) do
        {
          username:,
          cert_name:,
          cert_serial:,
          cert_subject:,
          cert_issuer:,
          mac: nil,
          called_station_id: nil,
          site_ip_address: nil,
          authentication_result:,
          task_id: "arn:aws:ecs:task_id",
          authentication_reply:,
          X509_Time_Valid_From: x509_valid_from,
          X509_Time_Valid_To: x509_valid_to,
          eap_type: "TLS",
        }.to_json
      end
      let(:post_auth_request) { post "/logging/post-auth", request_body }
      let(:cert_name) { "Example Certificate Common Name" }
      let(:cert_issuer) { "Example Issuer" }
      let(:cert_subject) { "Example Subject" }
      let(:cert_serial) { "Example Serial" }
      let(:x509_valid_from) { "2023-01-01 00:00:00" }
      let(:x509_valid_to) { "2024-01-01 00:00:00" }
      let(:authentication_result) { "Access-Accept" }
      let(:authentication_reply) { "This is a reply message" }

      before { post_auth_request }

      it "a session" do
        expect(Session.count).to eq(1)
      end

      it "the certificate common name" do
        expect(Session.first[:cert_name]).to eq("Example Certificate Common Name")
      end

      it "the certificate validity window" do
        expect(Session.first[:cert_valid_since].to_time).to eq(Time.utc(2023, 1, 1, 0, 0, 0))
        expect(Session.first[:cert_expiration].to_time).to eq(Time.utc(2024, 1, 1, 0, 0, 0))
      end
    end

    context "with a blank username" do
      let(:username) { "" }

      it_behaves_like "logging"
    end

    context "with a username" do
      let(:username) { "fakeusername" }

      it_behaves_like "logging"
    end
  end

  describe "user/pass post-auth logging (on new endpoint)" do
    let(:username) { "ABCDE" }
    let(:mac) { "DA-59-19-8B-39-2D" }
    let(:authentication_result) { "Access-Accept" }
    let(:authentication_reply) { "This is a reply message" }
    let(:request_body) do
      {
        username:,
        cert_name: nil,
        mac:,
        called_station_id: nil,
        site_ip_address: nil,
        authentication_result:,
        task_id: "arn:aws:ecs:task_id",
        authentication_reply:,
        eap_type: "MSCHAPV2",
      }.to_json
    end
    let(:post_auth_request) { post "/logging/post-auth", request_body }

    before do
      User.create(username:)
      post_auth_request
    end

    it "writes a session" do
      expect(Session.count).to eq(1)
    end

    it "writes the mac address" do
      expect(Session.first[:mac]).to eq(mac)
    end
    it "writes the eap_type" do
      expect(Session.first[:eap_type]).to eq("MSCHAP")
    end
  end
end
