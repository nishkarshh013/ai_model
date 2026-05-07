module AiModels
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'ai_models.logger' do
        AiModels.configuration.logger = ::Rails.logger if ::Rails.respond_to?(:logger) && ::Rails.logger
      end

      generators do
        require "generators/ai_models/install_generator"
        # require_relative '../../../generators/ai_models/install_generator'
      end
    end
  end
end
