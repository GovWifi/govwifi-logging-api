# frozen_string_literal: true

class Gdpr::UseCase::SessionDeletion
  def initialize(session_gateway:)
    @session_gateway = session_gateway
  end

  def execute
    session_gateway.delete_sessions
  end

private

  attr_reader :session_gateway
end
