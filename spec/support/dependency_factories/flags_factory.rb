# Quick Test class - Uses logger liberally for testing
class Flags
  def initialize(logger:, timing:, default_values:, hype_person: nil)
    @logger = logger
    @default_values = default_values
    @flags = default_values.dup
    @timing = timing
    @hype_person = hype_person
  end

  def fetch(name)
    @logger.info "HYPE INCOMING: #{@hype_person.hype}" if @hype_person
    @logger.debug "Flag fetched: #{name}"
    @timing.measure { @flags.fetch(name, @default_values.fetch(name)) }
  end

  def set(name, value)
    @logger.info "HYPE INCOMING: #{@hype_person.hype}" if @hype_person
    @logger.warn "Flag set: #{name}"
    @timing.measure { @flags[name] = value }
  end

  def reset(name)
    @logger.info "HYPE INCOMING: #{@hype_person.hype}" if @hype_person
    @logger.warn "Flag reset: #{name}"
    @timing.measure { @flags[name] = @default_values.fetch(name) }
  end

  def state
    @hype_person.hype if @hype_person
    @flags
  end
end

# Creates a flag handler. This does a few more interesting things considering that
# it requires `logger` which is a byproduct of the `LoggerFactory`.
#
# It also uses `timing` as an additional dep, and `hype_person` as an optional
class FlagsFactory < DependencyManager::Factory
  validate_with do
    required(:enabled).filled(:bool)
    required(:default_values).hash
  end

  def initialize(logger:, timing:, hype_person: nil, **dependencies)
    super(**dependencies)

    @logger = logger
    @timing = timing
    @hype_person = hype_person
  end

  def build
    return unless enabled?

    validate!

    load_requirements

    Flags.new(
      logger: @logger,
      timing: @timing,
      default_values: @factory_config[:default_values],
      hype_person: @hype_person
    )
  end

  def load_requirements
    # Assuming it wasn't in the header of this file
    # require 'flags'
  end

  def enabled?
    @factory_config[:enabled] == true
  end
end
