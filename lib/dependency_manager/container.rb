module DependencyManager
  class Container
    attr_reader :dependencies

    def initialize(app_context:, configuration:, dependency_tree: DependencyManager.dependency_map)
      @app_context = app_context

      # Typically loaded from some form of YAML
      @configuration = configuration

      @dependency_tree = dependency_tree
      @ordered_factory_dependencies = dependency_tree.tsort

      # And build the deps themselves
      @dependencies = build_dependencies
    end

    # Builds all the dependencies from factories
    #
    # @return [Hash[Symbol, Any]]
    #   Built resources
    def build_dependencies
      dependencies = {}

      # Take the ordered factories
      @ordered_factory_dependencies.each do |dependency|
        # Get their associated class
        factory = DependencyManager::Factory.get(dependency)

        # Figure out which dependencies we need, which are optional, and which
        # will break the factory build coming up
        resolved_dependencies = Resolver.new(
          factory: factory,
          loaded_dependencies: dependencies
        ).resolve

        # Create an instance of the factory including its resolved dependencies.
        factory_instance = factory.new(
          app_context:    @app_context,
          factory_config: get_config(factory),
          **resolved_dependencies
        )

        # ...and build the dependency based on the provided configuration options.
        dependencies[factory.dependency_name] = factory_instance.build
      end

      dependencies
    end

    # Fetch a dependency by name
    #
    # @param dependency [Symbol]
    #
    # @return [Any]
    def fetch(dependency)
      @dependencies.fetch(dependency)
    end

    # Gets the dependencies configuration from the master configuration.
    #
    # @param klass [Class]
    #   Class to get configuration for
    #
    # @return [Hash[Symbol, Any]]
    def get_config(klass)
      @configuration.fetch(klass.dependency_name, {})
    end
  end
end
