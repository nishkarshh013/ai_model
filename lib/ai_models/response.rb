module AiModels
  class Response
    attr_reader :content, :model, :tokens, :finish_reason, :raw

    def initialize(content:, model: nil, tokens: nil, finish_reason: nil, raw: nil)
      @content = content
      @model = model
      @tokens = tokens
      @finish_reason = finish_reason
      @raw = raw
    end

    def to_h
      {
        content: content,
        model: model,
        tokens: tokens,
        finish_reason: finish_reason,
        raw: raw
      }
    end
  end
end
