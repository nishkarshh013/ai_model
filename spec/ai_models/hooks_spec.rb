require 'spec_helper'
require 'stringio'

RSpec.describe 'request lifecycle hooks' do
  before do
    test_provider = Class.new(AiModels::Providers::Base) do
      def chat(messages:, model:, stream: false, **options, &block)
        payload = {
          model: model,
          messages: messages,
          stream: stream
        }.merge(options)

        with_request_lifecycle(model: model, messages: messages, request_payload: payload) do
          @attempts ||= 0
          @attempts += 1

          case config[:mode]
          when :retry_then_success
            raise Faraday::ConnectionFailed, 'temporary outage' if @attempts == 1

            AiModels::Response.new(
              content: 'ok after retry',
              model: model,
              raw: { attempts: @attempts }
            )
          when :error
            raise AiModels::Errors::AuthenticationError, 'bad token'
          when :stream
            accumulator = AiModels::Streaming::ResponseAccumulator.new
            %w[hello world].each do |content|
              chunk = AiModels::Response.new(content: content, model: model, raw: { content: content })
              accumulator.add(chunk)
              block.call(chunk)
            end
            accumulator.to_response
          else
            AiModels::Response.new(
              content: 'ok',
              model: model,
              raw: { attempts: @attempts }
            )
          end
        end
      end

      private

      def provider_key
        :hook_test
      end
    end

    AiModels::Providers::Registry.register(:hook_test, test_provider)
  end

  let(:messages) do
    [{ role: 'user', content: 'Explain Sidekiq' }]
  end

  it 'executes before_request and after_response hooks with structured context' do
    events = []

    AiModels.configure do |config|
      config.providers = {
        hook_test: {
          mode: :success
        }
      }

      config.before_request do |context|
        events << [
          :before,
          context.provider,
          context.model,
          context.messages,
          context.request_payload,
          context.retry_count
        ]
      end

      config.after_response do |context|
        events << [:after, context.response.content, context.latency.positive?, context.error]
      end
    end

    response = AiModels.chat(
      provider: :hook_test,
      model: 'demo-model',
      messages: messages
    )

    expect(response.content).to eq('ok')
    expect(events).to eq(
      [
        [:before, :hook_test, 'demo-model', messages, { model: 'demo-model', messages: messages, stream: false }, 0],
        [:after, 'ok', true, nil]
      ]
    )
  end

  it 'swallows hook failures and logs them' do
    log_output = StringIO.new
    follow_up_hooks = []

    AiModels.configure do |config|
      config.logger = Logger.new(log_output)
      config.providers = {
        hook_test: {
          mode: :success
        }
      }

      config.before_request do |_context|
        raise 'hook exploded'
      end

      config.after_response do |_context|
        follow_up_hooks << :after_response
      end
    end

    response = AiModels.chat(
      provider: :hook_test,
      model: 'demo-model',
      messages: messages
    )

    expect(response.content).to eq('ok')
    expect(follow_up_hooks).to eq([:after_response])
    expect(log_output.string).to include('before_request hook failed: RuntimeError: hook exploded')
  end

  it 'runs retry hooks and exposes retry count' do
    retry_events = []
    after_events = []

    AiModels.configure do |config|
      config.max_retries = 2
      config.retry_backoff = ->(_) { 0 }
      config.providers = {
        hook_test: {
          mode: :retry_then_success
        }
      }

      config.on_retry do |context|
        retry_events << [context.retry_count, context.error.class, context.latency.positive?]
      end

      config.after_response do |context|
        after_events << [context.retry_count, context.response.content]
      end
    end

    response = AiModels.chat(
      provider: :hook_test,
      model: 'demo-model',
      messages: messages
    )

    expect(response.content).to eq('ok after retry')
    expect(retry_events).to eq([[1, AiModels::Errors::ConnectionError, true]])
    expect(after_events).to eq([[1, 'ok after retry']])
  end

  it 'runs error hooks with the normalized error context' do
    error_events = []

    AiModels.configure do |config|
      config.max_retries = 0
      config.providers = {
        hook_test: {
          mode: :error
        }
      }

      config.on_error do |context|
        error_events << [
          context.provider,
          context.retry_count,
          context.error.class,
          context.error.message,
          context.latency.positive?
        ]
      end
    end

    expect do
      AiModels.chat(
        provider: :hook_test,
        model: 'demo-model',
        messages: messages
      )
    end.to raise_error(AiModels::Errors::AuthenticationError, 'bad token')

    expect(error_events).to eq(
      [[:hook_test, 0, AiModels::Errors::AuthenticationError, 'bad token', true]]
    )
  end

  it 'captures aggregated streaming responses in after_response hooks' do
    responses = []
    streamed_chunks = []

    AiModels.configure do |config|
      config.providers = {
        hook_test: {
          mode: :stream
        }
      }

      config.after_response do |context|
        responses << context.response
      end
    end

    AiModels.chat_stream(
      provider: :hook_test,
      model: 'demo-model',
      messages: messages
    ) do |chunk|
      streamed_chunks << chunk.content
    end

    expect(streamed_chunks).to eq(%w[hello world])
    expect(responses.first.content).to eq('helloworld')
    expect(responses.first.model).to eq('demo-model')
  end
end
