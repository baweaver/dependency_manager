require 'dependency_manager/config_schema_macros'
require 'set'

module DependencyManager
  # Base for all other factories, providing interface hints and generic
  # functionality
  #
  # ### Initialize for Dependency Specifications
  #
  # Every keyword argument used in the `initialize` function for a Factory
  # is used to resolve the dependencies of the class with the exception of
  # `CONTEXT_DEPENDENCIES`.
  #
  # `:keyreq` represents a required argument, while `:key` represents an
  # optional one:
  #
  # ```ruby
  # def initialize(logger:, optional_dependency: nil, **dependencies)
  #   super(**dependencies)
  #
  #   @logger = logger
  #   @optional_dependency = optional_dependency
  # end
  # ```
  #
  # This value could be `nil` or any other sane default value for the
  # dependency specified.
  #
  # The `Factory` implements several helper methods on its singleton class
  # like `dependencies`, `optional_dependencies`, and `factory_dependencies` to
  # help with constructing dependency chains.
  class Factory
    # Methods for validating configurations
    include ConfigSchemaMacros

    # Dependencies that are always present and injected at a top level
    # rather than by other factories
    CONTEXT_DEPENDENCIES = %i(app_context factory_config)

    # Keyword param types
    KEYWORD_ARGS = %i(keyreq key)
    OPTIONAL_ARG = :key

    class << self
      # Captures classes inheriting from Factory for later use
      #
      # @param subclass [Class]
      #   The subclass
      #
      # @return [void]
      def inherited(subclass)
        @factories ||= Set.new
        @factories.add subclass
      end

      # Get all available factory names except the Base factory
      #
      # @return [Array[Symbol]]
      def factories
        @factories || Set.new
      end

      # Get a factory by its underscored name
      #
      # @param factory_name [Symbol]
      #
      # @return [Symbol] Constant name
      def get(factory_name)
        const_name = constantize(factory_name)

        unless const_defined?(const_name)
          raise ArgumentError, "Tried to get non-existant Factory. Did you remember to define it?: #{const_name}"
        end

        const_get const_name
      end

      # Utility to constantize an underscored string or symbol
      #
      # @param s [String, Symbol]
      #
      # @return [Symbol]
      def constantize(s)
        s.to_s.split('_').map(&:capitalize).join.to_sym
      end

      def const_name
        to_s.split('::').last
      end

      # Name of the factory
      #
      # @return [String]
      def name
        underscore const_name
      end

      # Name of the expected dependency to be generated
      #
      # @return [Symbol]
      def dependency_name
        name.to_s.sub(/_factory$/, '').to_sym
      end

      def parameters
        instance_method(:initialize).parameters
      end

      # Dependencies of the class under the factory that it needs to initialize.
      #
      # @return [Array[Symbol]]
      def dependencies
        dependencies = parameters
          .select { |type, _name| KEYWORD_ARGS.include?(type) }
          .map(&:last)

        dependencies - CONTEXT_DEPENDENCIES
      end

      # Dependencies of the factory itself to make sure factories load in the
      # correct order.
      #
      # @return [Array[Symbol]]
      def factory_dependencies
        dependencies.map { |d| "#{d}_factory".to_sym }
      end

      # Dependencies required to build the factory
      #
      # @return [Array[Symbol]]
      def required_dependencies
        dependencies - optional_dependencies
      end

      # Optional arguments that are not strictly required, but used
      # for additional functionality.
      #
      # @return [Array[Symbol]]
      def optional_dependencies
        optionals = parameters
          .select { |type, _name| type == OPTIONAL_ARG }
          .map(&:last)

        optionals - CONTEXT_DEPENDENCIES
      end

      # Underscores a constant name
      #
      # @param const_name [Symbol]
      #
      # @return [Symbol]
      def underscore(const_name)
        const_name.gsub(/([^\^])([A-Z])/,'\1_\2').downcase.to_sym
      end
    end

    # Creates a new Factory.
    #
    # @param app_context: nil [AppContext]
    #   Application context information. Defaulted to `nil` in case users
    #   do not need this information.
    #
    # @param factory_config: [Hash[Symbol, Any]]
    #   Configuration specific to the factory
    #
    # @return [Factory]
    def initialize(app_context: nil, factory_config:)
      @app_context = app_context
      @factory_config = factory_config
    end

    # Used to build the dependency
    #
    # @raise [NotImplementedError]
    def build
      raise NotImplementedError
    end

    # Used to generate configuration for the dependency,
    # not always necessary for shorter builds.
    #
    # As a default will be an alias for `@factory_config`,
    # and is used as a hook point for any validation.
    #
    # @raise [Hash[Symbol, Any]]
    def configuration
      @configuration ||= deep_merge(default_configuration, @factory_config)
    end

    # Default configuration of the Factory
    #
    # @return [Hash[Symbol, Any]]
    def default_configuration
      {}
    end

    # Used to load and require any associated external dependencies.
    #
    # @raise [NotImplementedError]
    def load_requirements
      raise NotImplementedError
    end

    # Whether or not the dependency should be enabled. It is suggested to
    # use this as a guard when building dependencies:
    #
    # ```ruby
    # def build
    #   return unless enabled?
    #
    #   # ...
    # end
    # ```
    #
    # @return [FalseClass] Disabled by default
    def enabled?
      false
    end

    # Deeply merges two Hashes
    #
    # @param a [Hash]
    #   Original Hash
    #
    # @param b [Hash]
    #   Hash to merge
    #
    # @param &fn [Proc[Any, Any, Any]]
    #   Merging function
    #
    # @return [Hash]
    protected def deep_merge(a, b, &fn)
      deep_merge!(a.dup, b.dup, &fn)
    end

    # Destructive merge of two hashes
    #
     # @param a [Hash]
    #   Original Hash
    #
    # @param b [Hash]
    #   Hash to merge
    #
    # @param &fn [Proc[Any, Any, Any]]
    #   Merging function
    #
    # @return [Hash]
    protected def deep_merge!(a, b, &fn)
      a.merge!(b) do |key, left, right|
        next deep_merge(left, right, &fn) if left.is_a?(Hash) && right.is_a?(Hash)
        next fn.call(left, right, &fn) if block_given?

        right
      end
    end
  end
end
