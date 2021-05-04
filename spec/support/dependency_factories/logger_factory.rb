# Creates a generic Ruby logger with some configuration hooks
class LoggerFactory < DependencyManager::Factory
  validate_with do
    required(:enabled).filled(:bool)
    required(:level).value(included_in?: %i(warn danger info debug))
  end

  def build
    return false unless enabled?

    validate!

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
      level: :warn,
      out: STDOUT
    }.merge!(@factory_config)
  end

  def load_requirements
    require 'logger'
  end

  def enabled?
    @factory_config[:enabled] == true
  end
end
