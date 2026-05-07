module AiModels
  module Streaming
    class Parser
      DONE = :__done__

      def initialize(format:)
        @format = format
        @buffer = +''
      end

      def push(chunk)
        return [] if chunk.nil? || chunk.empty?

        @buffer << chunk

        case @format
        when :sse
          parse_sse_events
        when :jsonl
          parse_json_lines
        else
          raise ArgumentError, "Unsupported streaming format: #{@format}"
        end
      end

      def flush
        return [] if @buffer.empty?
        return [] if @format == :sse

        remainder = @buffer.strip
        @buffer.clear
        remainder.empty? ? [] : [Oj.load(remainder)]
      rescue Oj::ParseError
        []
      end

      private

      def parse_sse_events
        events = []

        while (separator_index = @buffer.index("\n\n"))
          raw_event = @buffer.slice!(0, separator_index + 2)
          data_lines = raw_event.lines.filter_map do |line|
            next unless line.start_with?('data:')

            line.sub('data:', '').strip
          end

          next if data_lines.empty?

          payload = data_lines.join("\n")
          events << (payload == '[DONE]' ? DONE : Oj.load(payload))
        end

        events
      end

      def parse_json_lines
        events = []

        while (newline_index = @buffer.index("\n"))
          line = @buffer.slice!(0, newline_index + 1).strip
          next if line.empty?

          events << Oj.load(line)
        end

        events
      rescue Oj::ParseError
        events
      end
    end
  end
end
