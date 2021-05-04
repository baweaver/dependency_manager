require 'dry/schema'

module DependencyManager
  module ConfigSchemaMacros
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def validate
      self.class.validate(**configuration)
    end

    def validate!
      validation_result = validate

      return true if validation_result.success?

      errors = validation_result
        .errors
        .map { |e| "#{e.path} #{e.text}" }
        .join(', ')

      raise ArgumentError, "Configuration is invalid: #{errors}"
    end

    module ClassMethods
      def validate_with(&dry_schema)
        @dry_schema = Dry::Schema.Params(&dry_schema)
      end

      def validate(**configuration)
        @dry_schema.call(configuration)
      end
    end
  end
end
