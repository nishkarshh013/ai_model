require 'spec_helper'

RSpec.describe AiModels::Streaming::Parser do
  describe 'SSE parsing' do
    it 'reassembles split OpenAI-style events' do
      parser = described_class.new(format: :sse)

      expect(parser.push('data: {"choices":[{"delta":{"content":"Hel')).to eq([])

      events = parser.push("lo\"}}],\"model\":\"demo\"}\n\ndata: [DONE]\n\n")

      expect(events).to eq(
        [
          {
            'choices' => [{ 'delta' => { 'content' => 'Hello' } }],
            'model' => 'demo'
          },
          described_class::DONE
        ]
      )
    end
  end

  describe 'JSONL parsing' do
    it 'parses complete lines and flushes a final trailing event' do
      parser = described_class.new(format: :jsonl)

      first_events = parser.push("{\"message\":{\"content\":\"Hi\"}}\n{\"message\":{\"content\":\"Bye\"}}")
      final_events = parser.flush

      expect(first_events).to eq(
        [
          {
            'message' => { 'content' => 'Hi' }
          }
        ]
      )
      expect(final_events).to eq(
        [
          {
            'message' => { 'content' => 'Bye' }
          }
        ]
      )
    end
  end
end
