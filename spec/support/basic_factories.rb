require_relative 'dependency_factories/logger_factory'
require_relative 'dependency_factories/flags_factory'
require_relative 'dependency_factories/timing_factory'
require_relative 'dependency_factories/hype_person_factory'

# Quick container for application context
class AppContext
  attr_reader :name, :env

  def initialize(name:, env: ENV['RAILS_ENV'])
    @name = name
    @env = env
  end
end

