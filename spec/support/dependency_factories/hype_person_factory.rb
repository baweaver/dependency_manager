# Optional dependency test
class HypePerson
  def initialize
  end

  def hype
    "HYPING THE THING!"
  end
end

# And a mostly optional factory
class HypePersonFactory < DependencyManager::Factory
  def initialize(**dependencies)
    super(**dependencies)
  end

  def build
    return unless enabled?

    HypePerson.new
  end

  def enabled?
    @factory_config[:enabled] == true
  end
end
