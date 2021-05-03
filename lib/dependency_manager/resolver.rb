module DependencyManager
  # Resolves a factories dependencies against the currently loaded dependency
  # list. Checks for potential missing dependencies and reconciles against
  # optional and required dependencies.
  class Resolver
    # Creates a new Resolver
    #
    # @param factory: [Factory]
    #   Factory instance
    #
    # @param loaded_dependencies: [Hash[Symbol, Any]]
    #   Map of currently loaded dependencies
    #
    # @return [Resolver]
    def initialize(factory:, loaded_dependencies:)
      @factory = factory
      @loaded_dependencies = loaded_dependencies
    end

    # Resolves dependencies from the currently loaded dependencies
    #
    # @raise [ArgumentError]
    #   When there are missing dependencies required by the current factory
    #   that will prevent the factory from building
    #
    # @return [Hash[Symbol, Any]]
    #   Dependencies necessary to build the factory
    def resolve
      # Resolve required dependencies from our current list
      resolved_dependencies = @loaded_dependencies.slice(*@factory.dependencies)
      required_dependencies = @factory.required_dependencies

      # But check if there are a few missing. Optional dependencies not included in this
      missing_dependencies = required_dependencies.reject do |dependency_name|
        !!resolved_dependencies[dependency_name]
      end

      if missing_dependencies.any?
        error = missing_dependencies.join(', ')
        raise ArgumentError, "Dependencies for `#{@factory.const_name}` are not present: #{error}"
      end

      resolved_dependencies
    end
  end
end
