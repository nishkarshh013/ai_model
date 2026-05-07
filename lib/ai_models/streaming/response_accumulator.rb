module AiModels
  module Streaming
    class ResponseAccumulator
      def initialize
        @content = +''
        @model = nil
        @tokens = nil
        @finish_reason = nil
        @raw = []
      end

      def add(chunk)
        @content << chunk.content.to_s
        @model = chunk.model if chunk.model
        @tokens = chunk.tokens if chunk.tokens
        @finish_reason = chunk.finish_reason if chunk.finish_reason
        @raw << chunk.raw if chunk.raw
      end

      def to_response
        Response.new(
          content: @content.empty? ? nil : @content,
          model: @model,
          tokens: @tokens,
          finish_reason: @finish_reason,
          raw: @raw
        )
      end
    end
  end
end
