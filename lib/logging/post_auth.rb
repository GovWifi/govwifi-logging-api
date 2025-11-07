module Logging
  class PostAuth
    def execute(params:)
      @params = params

      # The EAP Type determines whether this is a certificate-based or a
      # username/password MSCHAP connection session.
      return handle_username_request unless connection_type(eap_type) == "EAP-TLS"

      create_cert_session
    end

  private

    VALID_MAC_LENGTH = 17
    VALID_USERNAME_LENGTH = 6

    def create_user_session
      if valid_username?(username)
        Session.create(session_params.merge(username: username.to_s.upcase))
      else
        handle_invalid_username
      end
    end

    def valid_username?(username)
      username.to_s.length <= VALID_USERNAME_LENGTH
    end

    def handle_invalid_username
      puts "#{username} was invalid due to being longer than 6 characters, logging rejected"
    end

    def create_cert_session
      Session.create(
        session_params.merge(
          cert_name: @params.fetch("cert_name"),
          cert_serial: @params.fetch("cert_serial"),
          cert_issuer: @params.fetch("cert_issuer"),
          cert_subject: @params.fetch("cert_subject"),
          eap_type: eap_type,
        ),
      )
    end

    def session_params
      {
        start: Time.now,
        mac: formatted_mac(@params.fetch("mac")),
        ap: ap(@params.fetch("called_station_id")),
        siteIP: @params.fetch("site_ip_address"),
        building_identifier: building_identifier(@params.fetch("called_station_id")),
        success: access_accept?,
        task_id: @params.fetch("task_id"),
        authentication_reply: @params.fetch("authentication_reply"),
        eap_type: eap_type,
      }
    end

    def access_reject?
      @params.fetch("authentication_result") == "Access-Reject"
    end

    def access_accept?
      @params.fetch("authentication_result") == "Access-Accept"
    end

    def username
      @params.fetch("username")
    end

    def formatted_mac(unformatted_mac)
      MacFormatter.new.execute(mac: unformatted_mac)
    end

    def valid_mac?(mac)
      mac.to_s.length == VALID_MAC_LENGTH
    end

    def building_identifier(called_station_id)
      called_station_id unless valid_mac?(formatted_mac(called_station_id))
    end

    def ap(unformatted_mac)
      mac = formatted_mac(unformatted_mac)
      return mac if valid_mac?(mac)

      ""
    end

    def connection_type(eap_type)
      # Map EAP types received into what will be logged for that field
      case eap_type
        when "EAP-TLS"
          "EAP-TLS"
        when "NAK"
          "EAP-TLS"
        when "PEAP"
          "MSCHAP"
        else
          # Defaulting to "MSCHAP"
          "MSCHAP"
      end
    end

    def eap_type
      result = (@params[:eap_type] || "").upcase
      puts("\n\nEAP Type: '#{result}'\n\n")
      result
    end

    def handle_username_request
      return true if username == "HEALTH"

      create_user_session
    end
  end
end
