require 'dry/schema'

module DependencyManager
  # Class-level methods for validation of configurations
  module ConfigSchemaMacros
    # Hook for binding class-level methods to the child class
    #
    # @param klass [Class]
    #   Factory to bind to
    #
    # @return [void]
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # Runs validation against configuration without throwing errors
    #
    # @param target: configuration [Hash[Symbol, Any]]
    #   Configuration to validate, defaulting to `configuration`
    #
    # @return [Dry::Validation::Result]
    def validate(target: configuration)
      self.class.validate(**target)
    end

    # Immediate return validation that will raise an exception if the contract
    # is not fulfilled
    #
    # @param target: configuration [Hash[Symbol, Any]]
    #   Configuration to validate, defaulting to `configuration`
    #
    # @raises [ArgumentError]
    #   Failure
    #
    # @return [TrueClass]
    #   Success
    def validate!(target: configuration)
      validation_result = validate(target: target)

      return true if validation_result.success?

      errors = validation_result
        .errors
        .map { |e| "#{e.path} #{e.text}" }
        .join(', ')

      raise ArgumentError, "Configuration is invalid: #{errors}"
    end

    module ClassMethods
      # Class-level macro for validations
      #
      # @see https://dry-rb.org/gems/dry-validation
      #
      # @param &dry_schema [Proc]
      #   Dry Schema to validate with
      #
      # @return [Dry::Schema]
      def validate_with(&dry_schema)
        @dry_schema = Dry::Schema.Params(&dry_schema)
      end

      # Runs validator
      #
      # @param **configuration [Hash[Symbol, Any]]
      #   Hash to validate with schema
      #
      # @return [Dry::Validation::Result]
      def validate(**configuration)
        @dry_schema.call(configuration)
      end
    end
  end
end
