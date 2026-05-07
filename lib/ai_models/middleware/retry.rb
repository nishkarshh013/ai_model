module AiModels
  module Middleware
    class Retry
      class << self
        def apply(_builder, _options = {}, **)
          # Retries are executed in Providers::Base so the gem does not depend
          # on optional Faraday retry middleware packages.
        end
      end
    end
  end
end
