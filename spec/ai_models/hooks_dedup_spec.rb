require 'spec_helper'

RSpec.describe 'hook deduplication and reload safety' do
  it 'deduplicates hooks across repeated configure calls' do
    hook = proc { |_ctx| :noop }

    AiModels.configure do |config|
      config.before_request(&hook)
    end

    AiModels.configure do |config|
      config.before_request(&hook)
    end

    hooks = AiModels.configuration.hooks.register(:before_request)
    expect(hooks.size).to eq(1)
  end

  it 'supports resetting hooks explicitly' do
    AiModels.configure do |config|
      config.before_request { |_ctx| :noop }
    end

    expect(AiModels.configuration.hooks.register(:before_request).size).to eq(1)

    AiModels.configuration.reset_hooks!

    expect(AiModels.configuration.hooks.register(:before_request)).to eq([])

    AiModels.configure do |config|
      config.before_request { |_ctx| :noop }
    end

    expect(AiModels.configuration.hooks.register(:before_request).size).to eq(1)
  end

  it 'does not multiply hooks when a Rails initializer is evaluated repeatedly' do
    initializer = lambda do
      AiModels.configure do |config|
        config.before_request do |_ctx|
          :initializer
        end

        config.after_response do |_ctx|
          :initializer
        end
      end
    end

    initializer.call
    initializer.call

    expect(AiModels.configuration.hooks.register(:before_request).size).to eq(1)
    expect(AiModels.configuration.hooks.register(:after_response).size).to eq(1)
  end

  it 'is thread-safe when registering the same hook concurrently' do
    AiModels.configure do |config|
      config.providers = { hook_test: { mode: :success } }
    end

    hook = proc { |_ctx| :noop }
    hook_registrar = lambda do
      AiModels.configure do |config|
        config.before_request(&hook)
      end
    end

    threads = 10.times.map { Thread.new { hook_registrar.call } }
    threads.each(&:join)

    expect(AiModels.configuration.hooks.register(:before_request).size).to eq(1)
  end
end
