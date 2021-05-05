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

    Logger.new(
      configuration[:out],
      level: configuration[:level],
      formatter: proc { |severity, datetime, progname, msg|
        "[#{datetime}] (#{@app_context.env}/#{@app_context.name}) #{severity} -- #{msg}\n"
      }
    )
  end

  def default_configuration
    { level: :warn, out: STDOUT }
  end

  def load_requirements
    require 'logger'
  end

  def enabled?
    configuration[:enabled] == true
  end
end
