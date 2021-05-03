class Timing
  def initialize(logger:)
    @logger = logger
  end

  def measure(&fn)
    start_time = Time.now
    result = fn.call
    duration = Time.now - start_time

    @logger.info("[Timing] Took #{duration}")

    result
  end
end

# One more dependency to add some flavor
class TimingFactory < DependencyManager::Factory
  def initialize(logger:, hype_person: nil, **dependencies)
    super(**dependencies)

    @logger = logger
    @hype_person = hype_person
  end

  def build
    return unless enabled?

    Timing.new(logger: @logger)
  end

  def enabled?
    @factory_config[:enabled] == true
  end
end
