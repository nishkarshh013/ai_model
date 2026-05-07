module AiModels
  module Providers
    class OpenAICompatible < Base
      DEFAULT_PATH = '/v1/chat/completions'

      def chat(messages:, model:, stream: false, **options, &block)
        payload = {
          model: model,
          messages: messages
        }.merge(request_payload(options))

        payload[:stream] = true if stream

        if stream
          stream_chat(messages: messages, model: model, payload: payload, &block)
        else
          execute_chat(messages: messages, model: model, payload: payload)
        end
      end

      private

      def execute_chat(messages:, model:, payload:)
        with_request_lifecycle(model: model, messages: messages, request_payload: payload) do
          response = connection.post(chat_path) do |request|
            apply_request(request, payload)
          end

          handle_http_errors!(response)
          normalize_response(parse_json(response.body))
        end
      end

      def stream_chat(messages:, model:, payload:, &block)
        parser = Streaming::Parser.new(format: :sse)

        enum = Enumerator.new do |yielder|
          with_request_lifecycle(model: model, messages: messages, request_payload: payload) do
            accumulator = Streaming::ResponseAccumulator.new
            response = connection.post(chat_path) do |request|
              apply_request(request, payload)
              request.options.on_data = proc do |chunk, _bytes, _env|
                parser.push(chunk).each do |event|
                  next if event == Streaming::Parser::DONE

                  normalized_chunk = normalize_stream_chunk(event)
                  accumulator.add(normalized_chunk)
                  yielder << normalized_chunk
                end
              end
            end

            handle_http_errors!(response)
            parser.flush.each do |event|
              next if event == Streaming::Parser::DONE

              normalized_chunk = normalize_stream_chunk(event)
              accumulator.add(normalized_chunk)
              yielder << normalized_chunk
            end
            accumulator.to_response
          end
        end

        return enum unless block_given?

        enum.each(&block)
      end

      def normalize_response(body)
        choice = body.fetch('choices', []).first || {}

        Response.new(
          content: choice.dig('message', 'content') || body['text'],
          model: body['model'],
          tokens: normalize_tokens(body['usage']),
          finish_reason: choice['finish_reason'],
          raw: body
        )
      end

      def normalize_stream_chunk(body)
        choice = body.fetch('choices', []).first || {}

        Response.new(
          content: choice.dig('delta', 'content') || choice.dig('message', 'content'),
          model: body['model'],
          tokens: normalize_tokens(body['usage']),
          finish_reason: choice['finish_reason'],
          raw: body
        )
      end

      def request_payload(options)
        options.except(:headers)
      end

      def apply_request(request, payload)
        request.headers['Authorization'] = "Bearer #{api_key}" if api_key.present?
        custom_headers.each do |key, value|
          request.headers[key] = value
        end
        request.options.timeout = request_options[:timeout]
        request.options.open_timeout = request_options[:open_timeout]
        request.body = encode_json(payload)
      end

      def connection
        @connection ||= build_connection(base_url)
      end

      def base_url
        config[:url] || raise(Errors::ProviderError, 'Provider URL is not configured')
      end

      def chat_path
        config[:path] || DEFAULT_PATH
      end

      def api_key
        config[:api_key]
      end

      def custom_headers
        config.fetch(:headers, {})
      end
    end
  end
end
