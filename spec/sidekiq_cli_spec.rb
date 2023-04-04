# frozen_string_literal: true

require 'open3'

describe 'sidekiq CLI' do
  it 'runs without errors' do
    skip 'this slow integration spec only runs in CI' unless ENV['CIRCLECI']

    # Inspired by: https://github.com/sidekiq/sidekiq/issues/3214
    # Kick off sidekiq, wait a bit, and make sure the output doesn't include errors.
    # It's slow, but appears to be the only way to detect errors outside the workers.
    errors = Open3.popen2e('bundle exec sidekiq') do |_stdin, stdout_and_stderr, wait_thread|
      sleep 30
      Process.kill('KILL', wait_thread.pid)
      # certain errors are written to STDOUT, so we look at both STDOUT and STDERR
      stdout_and_stderr.select { |line| line.include?('ERROR') }
    end

    expect(errors).to be_empty
  end
end
