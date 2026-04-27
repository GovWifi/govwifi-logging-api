# frozen_string_literal: true

desc "Smoke tests cleanup"
task smoke_tests_cleanup: :load_env do
  Smoketests::SmoketestCleanup.new.clean
end
