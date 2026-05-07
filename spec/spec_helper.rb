require 'bundler/setup'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/ai_models'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before do
    AiModels.reset!
  end
end
