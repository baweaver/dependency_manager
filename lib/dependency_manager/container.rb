require 'set'

module DependencyManager
  class Container
    # A container should only be built once
    class BuildOnceError < ArgumentError; end

    # You can't add new dependencies after a build
    class AddedFactoryAfterBuildError < ArgumentError; end

    attr_reader :dependencies

    # Creates a new Dependency Container
    #
    # @param app_context: [Any]
    #   Contextual information for the currently running application
    #
    # @param configuration: [Hash[Symbol, Any]]
    #   Hash of configuration values, typically loaded from a YAML or JSON file
    #
    # @param factories: Factory.factories [Array[Factory]]
    #   All factories to build dependency chain from. This will default to the
    #   `Factory.factories` method, which will grab all children of the base
    #   `Factory` class.
    #
    # @return [Container]
    def initialize(app_context:, configuration:, factories: Factory.factories)
      @app_context = app_context
      @configuration = configuration
      @factories = factories.is_a?(Set) ? factories : Set[*factories]
      @built = false
    end

    # Register a factory explicitly
    #
    # @param factory [type] [description]
    #
    # @return [type] [description]
    def register(factory)
      raise AddedFactoryAfterBuildError, "Cannot add Factories after Container has been built" if @built

      @factories.add factory
    end

    # Builds all the dependencies from factories
    #
    # @return [Hash[Symbol, Any]]
    #   Built resources
    def build
      raise BuildOnceError, "Cannot build more than once" if @built

      @dependency_tree = dependency_tree
      @ordered_factory_dependencies = dependency_tree.tsort

      @dependencies = {}

      # Take the ordered factories
      @ordered_factory_dependencies.each do |factory_name|
        # Get their associated class
        factory = DependencyManager::Factory.get(factory_name)

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
        @dependencies[factory.dependency_name] = factory_instance.build
      end

      @built = true

      @dependencies
    end

    # Fetch a dependency by name
    #
    # @param dependency [Symbol]
    #
    # @return [Any]
    def fetch(dependency)
      @dependencies.fetch(dependency)
    end

    # Listing of all dependencies
    #
    # @return [Hash[Symbol, Any]]
    def to_h
      @dependencies
    end

    def dependency_tree
      DependencyTree.new(dependency_hash)
    end

    private def dependency_hash
      @factories.map { |k| [k.name, k.factory_dependencies] }.to_h
    end

    # Gets the dependencies configuration from the master configuration.
    #
    # @param klass [Class]
    #   Class to get configuration for
    #
    # @return [Hash[Symbol, Any]]
    private def get_config(klass)
      @configuration.fetch(klass.dependency_name, {})
    end
  end
end
