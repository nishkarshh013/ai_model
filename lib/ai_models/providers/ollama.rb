module AiModels
  module Providers
    class Ollama < Base
      DEFAULT_URL = 'http://localhost:11434'
      DEFAULT_PATH = '/api/chat'

      def chat(messages:, model:, stream: false, **options, &block)
        payload = {
          model: model,
          messages: messages,
          stream: stream
        }.merge(request_payload(options))

        if stream
          stream_chat(messages: messages, model: model, payload: payload, &block)
        else
          execute_chat(messages: messages, model: model, payload: payload)
        end
      end

      private

      def execute_chat(messages:, model:, payload:)
        model_to_use = resolve_model_alias(model)
        payload[:model] = model_to_use

        with_request_lifecycle(model: model_to_use, messages: messages, request_payload: payload) do
          response = connection.post(chat_path) do |request|
            request.options.timeout = request_options[:timeout]
            request.options.open_timeout = request_options[:open_timeout]
            request.body = encode_json(payload)
          end

          handle_http_errors!(response)
          normalize_response(parse_json(response.body))
        end
      end

      def stream_chat(messages:, model:, payload:, &block)
        parser = Streaming::Parser.new(format: :jsonl)

        enum = Enumerator.new do |yielder|
          model_to_use = resolve_model_alias(model)
          payload[:model] = model_to_use

          with_request_lifecycle(model: model_to_use, messages: messages, request_payload: payload) do
            accumulator = Streaming::ResponseAccumulator.new
            response = connection.post(chat_path) do |request|
              request.options.timeout = request_options[:timeout]
              request.options.open_timeout = request_options[:open_timeout]
              request.body = encode_json(payload)
              request.options.on_data = proc do |chunk, _bytes, _env|
                parser.push(chunk).each do |event|
                  normalized_chunk = normalize_stream_chunk(event)
                  accumulator.add(normalized_chunk)
                  yielder << normalized_chunk
                end
              end
            end

            handle_http_errors!(response)
            parser.flush.each do |event|
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
        Response.new(
          content: extract_content(body),
          # content: body.dig('message', 'content'),
          model: body['model'],
          tokens: normalize_tokens_from_ollama(body),
          finish_reason: body['done_reason'] || default_finish_reason(body),
          raw: body
        )
      end

      def normalize_stream_chunk(body)
        Response.new(
          content: extract_content(body),
          # content: body.dig('message', 'content'),
          model: body['model'],
          tokens: normalize_tokens_from_ollama(body),
          finish_reason: body['done_reason'] || default_finish_reason(body),
          raw: body
        )
      end

      def normalize_tokens_from_ollama(body)
        prompt_tokens = body['prompt_eval_count']
        completion_tokens = body['eval_count']

        return if prompt_tokens.nil? && completion_tokens.nil?

        {
          prompt_tokens: prompt_tokens,
          completion_tokens: completion_tokens,
          total_tokens: [prompt_tokens, completion_tokens].compact.sum
        }
      end

      def default_finish_reason(body)
        body['done'] ? 'stop' : nil
      end

      def request_payload(options)
        options.except(:headers)
      end

      def connection
        @connection ||= build_connection(base_url)
      end

      def base_url
        config[:url] || DEFAULT_URL
      end

      def chat_path
        config[:path] || DEFAULT_PATH
      end

      # Try to map a requested model name to one available on the Ollama server.
      # If no mapping is found, returns the original `model`.
      def resolve_model_alias(model)
        return model unless model.is_a?(String)

        available = fetch_available_models
        return model if available.empty?

        # Normalize requested form(s) for comparison
        requested = model.to_s.downcase
        requested_dash = requested.tr('.', '-')

        # Exact match first
        match = available.find { |m| [requested, requested_dash].include?(m.to_s.downcase) }
        return match if match

        # Partial / fuzzy matches: contains or same prefix
        match = available.find do |m|
          m.to_s.downcase.include?(requested_dash) || m.to_s.downcase.start_with?(requested.split(/[.-]/).first)
        end
        match || model
      rescue StandardError => _e
        model
      end

      def fetch_available_models
        resp = connection.get('/api/tags')
        return [] unless resp.success?

        body = parse_json(resp.body)

        case body
        when Array
          body.map { |entry| entry.is_a?(Hash) ? (entry['model'] || entry['name'] || entry['id']) : entry }
        when Hash
          if body['models'].is_a?(Array)
            body['models'].map { |e| e.is_a?(Hash) ? (e['model'] || e['name'] || e['id']) : e }
          else
            []
          end
        else
          []
        end
      rescue StandardError => _e
        []
      end

      def extract_content(body)
        case body
        when Hash
          body.dig('message', 'content') ||
            body['response'] ||
            body['content']
        when String
          body
        end
      end
    end
  end
end
