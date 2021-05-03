# Creates a generic Ruby logger with some configuration hooks
class LoggerFactory < DependencyManager::Factory
  def build
    return false unless enabled?

    load_requirements

    Logger.new(configuration[:out]).tap do |logger|
      logger.level = configuration.fetch(:level, :warn)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] (#{@app_context.env}/#{@app_context.name}) #{severity} -- #{msg}\n"
      end
    end
  end

  def configuration
    @configuration ||= {
      level: @factory_config.fetch(:level, :warn),
      out: @factory_config.fetch(:out, STDOUT)
    }
  end

  def load_requirements
    require 'logger'
  end

  def enabled?
    @factory_config[:enabled] == true
  end
end