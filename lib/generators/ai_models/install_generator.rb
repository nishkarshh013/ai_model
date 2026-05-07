require 'rails/generators'

module AiModels
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates an initializer for AiModels'

      def copy_initializer
        template 'ai_models.rb', 'config/initializers/ai_models.rb'
      end
    end
  end
end
