task daily_session_deletion: :load_env do
  session_gateway = Gdpr::Gateway::Session.new
  Gdpr::UseCase::SessionDeletion.new(session_gateway:).execute
end
