# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog:
https://keepachangelog.com/en/1.1.0/

## [0.1.0-alpha] - 2026-05-18

### Added

#### Core architecture
- Rails-native AI provider abstraction layer
- Unified `AiModels.chat` API
- Unified `AiModels.chat_stream` API
- Provider registry and adapter isolation
- Normalized `AiModels::Response` object

#### Provider support
- Native Ollama provider implementation
- DeepSeek provider support
- OpenAI-compatible provider abstraction
- LM Studio support
- Groq adapter support
- OpenRouter adapter support
- LocalAI adapter support
- vLLM adapter support

#### Streaming
- Streaming support via callback blocks
- Enumerator-based streaming support
- SSE streaming parser support
- JSONL streaming parser support
- Unified streaming lifecycle across providers

#### Rails integration
- Rails Railtie integration
- Install generator for initializer setup
- Rails-friendly configuration API

#### Request lifecycle
- Retry lifecycle handling
- Request lifecycle hooks
- Error normalization
- Provider-independent middleware support

#### Tooling
- RSpec test suite
- RuboCop configuration
- WebMock integration for provider testing

### Notes
- Initial alpha release.
- Core architecture and streaming validated against local and OpenAI-compatible providers.
- APIs may evolve before stable v1 release.