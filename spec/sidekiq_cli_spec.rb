# frozen_string_literal: true

require 'open3'

describe 'sidekiq CLI' do
  it 'runs without errors' do
    skip 'this slow integration spec only runs in CI' unless ENV['CIRCLECI']

    # Inspired by: https://github.com/sidekiq/sidekiq/issues/3214
    # Kick off sidekiq, wait a bit, and make sure the output doesn't include errors.
    # It's slow, but appears to be the only way to detect errors outside the workers.
    errors = []
    thread = nil
    Open3.popen2e('bundle exec sidekiq') do |_stdin, stdout_and_stderr, wait_thread|
      thread = wait_thread
      sleep 30
      # Use system-specific tools or Ruby methods to check if the process is alive
      if process_alive?(wait_thread.pid)
        Process.kill('KILL', wait_thread.pid)
      end

      errors = stdout_and_stderr.read.split("\n").select { |line| line.include?('ERROR') }
    end

    Process.kill('KILL', thread.pid) if process_alive?(thread.pid)

    expect(errors).to be_empty
  end

  def process_alive?(pid)
    Process.getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end
end
