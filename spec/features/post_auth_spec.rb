describe App do
  before do
    DB[:sessions].truncate
    DB[:userdetails].truncate
  end

  describe 'POST post-auth' do
    let(:username) { 'vykzdx' }
    let(:mac) { 'da-59-19-8b-39-2d' }
    let(:called_station_id) { '01-39-38-25-2a-80' }
    let(:site_ip_address) { '93.11.238.187' }
    let(:post_auth_request) { get "/logging/post-auth/user/#{username}/mac/#{mac}/ap/#{called_station_id}/site/#{site_ip_address}/result/#{authentication_result}" }
    let(:user) { User.find(username: username) }
    let(:authentication_result) { 'Access-Accept' }

    before do
      User.create(username: username)
      post_auth_request
    end

    context 'Access-Accept' do
      context 'GovWifi user' do
        it 'creates a single session record' do
          expect(Session.count).to eq(1)
        end

        it 'records the session details' do
          session = Session.first

          expect(session.username).to eq(username)
          expect(session.mac).to eq(mac)
          expect(session.ap).to eq(called_station_id)
          expect(session.siteIP).to eq(site_ip_address)
          expect(session.building_identifier).to eq(called_station_id)
        end

        context 'user last login' do
          context 'HEALTH user' do
            let(:username) { 'HEALTH' }

            it 'does not update the last login' do
              post_auth_request
              expect(user.last_login).to be_nil
            end
          end

          context 'GovWifi user' do
            it 'does updates the last login' do
              post_auth_request
              expect(user.last_login).to_not be_nil
            end
          end
        end
      end
    end

    context 'Access-Reject' do
      let(:authentication_result) { 'Access-Reject' }


      it 'does not record last_login for the user' do
        post_auth_request
        expect(user.last_login).to be_nil
      end
    end

    it 'returns a 204 OK' do
      post_auth_request
      expect(last_response.status).to eq(204)
    end

    context 'Unknown authentication result' do
      let(:authentication_result) { 'unknown' }

      it 'returns a 404 for anything other than Access-Accept or Access-Reject' do
        post_auth_request
        expect(last_response.status).to eq(404)
      end
    end

    context 'Blank authentication result' do
      let(:authentication_result) { '' }

      it 'returns a 404 for anything other than Access-Accept or Access-Reject' do
        post_auth_request
        expect(last_response.status).to eq(404)
      end
    end
  end
end
